from flask import request, jsonify
from flask_restful import Resource
import base64
import config  # same as DeleteEmployee

class UpdateEmployee(Resource):
    def post(self, emp_id):
        try:
            data = request.get_json()

            emp_name = data.get('name')
            emp_bg = data.get('bg')
            emp_email = data.get('emp_email')
            emp_address = data.get('address')
            emp_phone = data.get('phone')
            emp_position = data.get('position')
            emp_photo_base64 = data.get('emp_photo')

            emp_photo_binary = None
            if emp_photo_base64:
                emp_photo_binary = base64.b64decode(emp_photo_base64)

            cursor = config.conn.cursor()  # ✅ Use existing connection

            update_query = '''
                UPDATE tblEmployees
                SET
                    emp_name = ?,
                    emp_bg = ?,
                    emp_mail = ?,
                    emp_address = ?,
                    emp_phone_number = ?,
                    position = ?,
                    emp_photo = ?
                WHERE emp_id = ?
            '''

            cursor.execute(update_query, (
                emp_name,
                emp_bg,
                emp_email,
                emp_address,
                emp_phone,
                emp_position,
                emp_photo_binary,
                emp_id
            ))

            config.conn.commit()
            cursor.close()

            return jsonify({'status': 'success', 'message': 'Employee updated successfully'})

        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)})
