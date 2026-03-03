from flask_restful import Resource
from flask import jsonify, request
import config

class GetEmployeeTempDetails(Resource):
    def get(self, emp_id):
        try:
            cursor = config.conn.cursor()
            cursor.execute("""
                SELECT emp_id, emb_no, CONVERT(VARCHAR, created_date, 120) AS created_date
                FROM tblEmbeddings
                WHERE emp_id = ? AND emb_type = 'temp'
                ORDER BY emb_no ASC
            """, emp_id)
            rows = cursor.fetchall()

            embeddings = []
            for row in rows:
                embeddings.append({
                    "emb_no": row[1],
                    "created_date": row[2]
                })

            result = {
                "emp_id": emp_id,
                "embeddings": embeddings
            }
            return jsonify(result)
        except Exception as e:
            return jsonify({"error": str(e)})
