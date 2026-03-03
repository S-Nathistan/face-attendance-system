from flask_restful import Resource
from flask import jsonify, request
import config

cursor = config.conn.cursor()

class UpdateAdmin(Resource):
    def put(self, admin_id):
        request_data = request.get_json()
        name = request_data.get('name')
        username = request_data.get('username')
        position = request_data.get('position')
        password = request_data.get('password')  # New Password

        if not name or not username or not position:
            return jsonify({"status": "fail", "message": "Name, Username, and Position are required"})

        # Update name, username, position first
        cursor.execute(
            "UPDATE tblAdmin SET name = ?, username = ?, position = ? WHERE admin_id = ?",
            (name, username, position, admin_id)
        )
        
        # If password is given and not empty, update password too
        if password and password.strip() != "":
            cursor.execute(
                "UPDATE tblAdmin SET password = ? WHERE admin_id = ?",
                (password, admin_id)
            )

        config.conn.commit()

        cursor.execute(
            "SELECT * FROM tblAdmin WHERE admin_id = ?", (admin_id,)
        )
        admin = cursor.fetchone()

        if admin:
            columns = [column[0] for column in cursor.description]
            admin_dict = dict(zip(columns, admin))
            return jsonify({"status": "success", "admin": admin_dict})
        else:
            return jsonify({"status": "fail", "message": "Admin not found"})
