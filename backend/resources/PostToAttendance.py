from flask import request
from flask_restful import Resource
from datetime import datetime
import base64
from PIL import Image
import io
import config
from datetime import datetime, timedelta
from resources.processFaceAttendance import load_embeddings_cache


cursor = config.conn.cursor()

class PostToAttendance(Resource):
    def post(self):
        try:
            data = request.get_json()
            if not data or 'qr' not in data or 'status' not in data:
                return {"status": "fail", "error": "Invalid request"}, 400
                
            emp_id = data['qr']
            status = data['status']

            print(f"Received Employee ID (qr): {emp_id}")
            print(f"Received Attendance Status: {status}")

            embedding_base64 = data['embedding']

            # print(f"Received Attendance embedding: {embedding_base64}")

            # Decode the base64 encoded embedding
            embedding_bytes = base64.b64decode(embedding_base64)

            # print(f"Received Attendance embedding bytes: {embedding_bytes}")
                
            # Insert new record
            cursor.execute("""
                INSERT INTO tblAttendance (FK_emp_id, time_stamp, att_type)
                VALUES (?, GETDATE(), ?)
            """, (emp_id, status))

            # print(f"Received embedding base64: {embedding_base64[:50]}...")  # Print partial to avoid clutter
            # print(f"Status received: {status}")
            # Handle embedding update logic
            if status == "Sign-out" and embedding_bytes:
                self.update_embeddings(emp_id, embedding_bytes)

            config.conn.commit()
            
            return {"status": "success", "message": "Attendance marked"}
            
        except Exception as e:
            return {"status": "error", "error": str(e)}, 500
        

    def update_embeddings(self, emp_id, new_embedding):
        print(f"Updating embeddings for {emp_id}")

        four_months_ago = datetime.now() - timedelta(days=120)

        # 1️⃣ Get latest embedding date
        cursor.execute("""
            SELECT TOP 1 created_date 
            FROM tblEmbeddings 
            WHERE emp_id = ? 
            ORDER BY created_date DESC
        """, (emp_id,))
        row = cursor.fetchone()
        if not row:
            print(f"No embeddings found for {emp_id}")
            return

        latest_date = row[0]
        print(f"Latest embedding date for {emp_id}: {latest_date}")


        if latest_date >= four_months_ago:
            print(f"Skipping update for {emp_id} — latest embedding is recent.")
            return  # Skip updating — latest embedding is recent.

        # 2️⃣ Get temp embeddings only (6-8)
        cursor.execute("""
            SELECT id, emb_no, created_date
            FROM tblEmbeddings
            WHERE emp_id = ? AND emb_no IN (6, 7, 8)
            ORDER BY created_date ASC
        """, (emp_id,))
        temp_rows = cursor.fetchall()
        print(f"Temp embeddings for {emp_id}: {temp_rows}")

        # Handle case where there are no temp embeddings (first time)
        if len(temp_rows) == 0:
            # Insert first temporary embedding with emb_no = 6
            cursor.execute("""
                INSERT INTO tblEmbeddings (emp_id, embedding, created_date, emb_no, emb_type)
                VALUES (?, ?, GETDATE(), 6, 'temp')
            """, (emp_id, new_embedding))
            print(f"First temp embedding added with emb_no 6 for {emp_id}")
        else:
            # If there are already temp embeddings (6, 7, or 8), insert into next available one
            if len(temp_rows) < 3:
                next_emb_no = min(set([6, 7, 8]) - {row[1] for row in temp_rows})
                cursor.execute("""
                    INSERT INTO tblEmbeddings (emp_id, embedding, created_date, emb_no, emb_type)
                    VALUES (?, ?, GETDATE(), ?, 'temp')
                """, (emp_id, new_embedding, next_emb_no))
                print(f"New temp embedding added with emb_no {next_emb_no} for {emp_id}")
            else:
                # Replace the oldest temp embedding (if there are 3 temp embeddings)
                oldest_id = temp_rows[0][0]
                cursor.execute("""
                    UPDATE tblEmbeddings
                    SET embedding = ?, created_date = GETDATE()
                    WHERE id = ?
                """, (new_embedding, oldest_id))
                print(f"Oldest temp embedding replaced for {emp_id} (ID {oldest_id})")

        # Commit after embedding update
        config.conn.commit()
        print(f"Committed changes for {emp_id}")
        load_embeddings_cache()