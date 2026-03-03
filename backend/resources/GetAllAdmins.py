from flask_restful import Resource
from flask import jsonify
import config


class GetAllAdmins(Resource):
    def get(self):
        try:
            cursor = config.conn.cursor()
            cursor.execute("""
            SELECT admin_id, name, username, password, position, 
            ISNULL(protected, 0) AS protected 
            FROM tblAdmin
        """)
            rows = cursor.fetchall()

            admin_list = []
            for row in rows:
                admin_list.append({
                    "admin_id": row.admin_id,
                    "name": row.name,
                    "username": row.username,
                    "password": row.password,  
                    "position": row.position,
                    "protected": row.protected or 0
                })

            return jsonify(admin_list)
        except Exception as e:
            return jsonify({"error": str(e)})
