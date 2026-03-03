from flask_restful import Resource
from flask import jsonify, request
import json
import config

cursor = config.conn.cursor()

class DeleteAdmin(Resource):
    def delete(self, admin_id):
        try:
            print(f"Attempting to delete admin with ID: {admin_id}")
            # Check if admin exists
            cursor.execute(f"SELECT * FROM tblAdmin WHERE admin_id = '{admin_id}'")
            admin = cursor.fetchone()
            
            if not admin:
                return jsonify({"status": "fail", "message": "Admin not found"})

            # Delete admin from the table
            cursor.execute(f"DELETE FROM tblAdmin WHERE admin_id = '{admin_id}'")
            config.conn.commit()

            return jsonify({"status": "success", "message": "Admin deleted successfully"})
        
        except Exception as e:
            return jsonify({"status": "fail", "message": f"Error: {str(e)}"})
