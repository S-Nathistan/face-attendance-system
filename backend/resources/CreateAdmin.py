from flask_restful import Resource
from flask import jsonify, request
import json
import config

cursor = config.conn.cursor()

class CreateAdmin(Resource):
    def post(self):
        request_data = request.data
        request_data = json.loads(request_data.decode('utf-8'))

        name = request_data.get('name')
        username = request_data.get('username')
        password = request_data.get('password')
        position = request_data.get('position')  # Receive the position data

        # Check if required fields are provided
        if not name or not username or not password or not position:
            return jsonify({"status": "fail", "message": "Missing required fields"})

        # Check if the username already exists
        cursor.execute(f"SELECT * FROM tblAdmin WHERE username = '{username}'")
        existing_admin = cursor.fetchone()
        if existing_admin:
            return jsonify({"status": "fail", "message": "Username already exists"})

        # Insert new admin into the database
        cursor.execute(
            "INSERT INTO tblAdmin (name, username, password, position) VALUES (?, ?, ?, ?)",
            (name, username, password, position)  # Include position in the insertion
        )
        config.conn.commit()

        return jsonify({"status": "success", "message": "Admin created successfully"})
