from flask import request
from flask_restful import Resource
from datetime import datetime
import base64
from PIL import Image
import io
import config

cursor = config.conn.cursor()

def compress_image(image_bytes, max_size=(150, 150)):
    try:
        image = Image.open(io.BytesIO(image_bytes))
        image = image.convert("RGB")
        image.thumbnail(max_size)
        output_buffer = io.BytesIO()
        image.save(output_buffer, format='JPEG', quality=75)
        return output_buffer.getvalue()
    except Exception as e:
        print("Image compression error:", e)
        return image_bytes


class GetForAttendance(Resource):
    def post(self):
        data = request.get_json()
        emp_id = data.get("qr")

        if not emp_id:
            return {"data": 0, "name": "", "lastatt": ""}

        query = """
            SELECT e.emp_id, e.emp_name, e.emp_bg, e.emp_dob, e.emp_phone_number, e.emp_address,
                   e.emp_mail, e.position, e.created_date, e.emp_photo,
                   a.att_type, a.time_stamp
            FROM tblEmployees e
            LEFT JOIN (
                SELECT TOP 1 att_type, time_stamp
                FROM tblAttendance
                WHERE FK_emp_id = ?
                ORDER BY time_stamp DESC
            ) a ON e.emp_id = ?
            WHERE e.emp_id = ?
        """
        cursor.execute(query, (emp_id, emp_id, emp_id))
        row = cursor.fetchone()

        if not row:
            return {"data": 0, "name": "", "lastatt": ""}

        last_att = row.att_type or ""
        date = row.created_date.strftime("%d-%m-%y")
        photo_base64 = None

        if row.emp_photo:
            compressed_photo = compress_image(row.emp_photo)
            photo_base64 = base64.b64encode(compressed_photo).decode("utf-8")

        return {
            "data": 2,
            "name": row.emp_name,
            "status": last_att,
            "date": date,
            "time": row.created_date.strftime("%H:%M:%S"),
            "position": row.position,
            "blood-group": row.emp_bg,
            "address": row.emp_address,
            "phone-number": row.emp_phone_number,
            "dob": row.emp_dob.strftime('%Y-%m-%d'),
            "created_date": date,
            "emp_photo": photo_base64,
            "lastatt": last_att
        }






