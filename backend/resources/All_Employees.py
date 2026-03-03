from datetime import datetime
from Model import Employee
from flask_restful import Resource
from flask import jsonify, request, Flask
import json
import config
from PIL import Image
import io
import base64
import config

cursor = config.conn.cursor()

def compress_image(image_bytes, quality=100):
    try:
        image = Image.open(io.BytesIO(image_bytes))
        image = image.convert("RGB")
        image.thumbnail((500, 500))
        # image.thumbnail(max_size)  # Resize to max dimensions, maintaining aspect ratio
        output_buffer = io.BytesIO()
        image.save(output_buffer, format='JPEG', quality=quality)  # Reduce quality to compress
        return output_buffer.getvalue()
    except Exception as e:
        print("Image compression error:", e)
        return image_bytes  # fallback to original if compression fails


class AllEmployees(Resource):

    def get(self):
        id_query = """
            SELECT e.emp_id, e.emp_name, e.emp_bg, e.emp_dob, e.emp_phone_number, e.emp_address,
                   e.emp_mail, e.position, e.created_date, e.emp_photo,
                   a.att_type, a.time_stamp
            FROM tblEmployees e
            LEFT JOIN (
                SELECT FK_emp_id, att_type, time_stamp
                FROM tblAttendance a1
                WHERE time_stamp = (
                    SELECT MAX(time_stamp)
                    FROM tblAttendance a2
                    WHERE a2.FK_emp_id = a1.FK_emp_id
                )
            ) a ON e.emp_id = a.FK_emp_id
            ORDER BY e.emp_name ASC
        """
        
        cursor.execute(id_query)
        results = []

        for row in cursor.fetchall():
            time_stamp = getattr(row, 'time_stamp', None)
            att_type = getattr(row, 'att_type', 'None')

            if time_stamp is None:
                date = 'newly added'
                time = ''
            else:
                date = time_stamp.strftime("%d-%m-%y")
                time = time_stamp.strftime("%H:%M:%S")

            joined_date = row.created_date.strftime("%d-%m-%y")
            photo_base64 = None

            if row.emp_photo:
                # Resize and encode
                compressed_photo = compress_image(row.emp_photo)
                photo_base64 = base64.b64encode(compressed_photo).decode('utf-8')

            results.append({
                'emp_id': row.emp_id,
                'emp_name': row.emp_name,
                'status': att_type,
                'date': date,
                'time': time,
                'position': row.position,
                "blood-group": row.emp_bg,
                "address": row.emp_address,
                "phone-number": row.emp_phone_number,
                "dob": row.emp_dob.strftime('%Y-%m-%d'),
                'created_date': joined_date,
                'emp_photo': photo_base64,
                'emp_email': row.emp_mail,
            })

        return jsonify(results)
