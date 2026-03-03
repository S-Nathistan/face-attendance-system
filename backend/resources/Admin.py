from flask import jsonify
from flask_restful import Resource
import config

cursor = config.conn.cursor()


class Admin(Resource):
    def get(self):
        query = f"select admin_id, name , username, password from tblAdmin"
        cursor.execute(query)
        results = cursor.fetchall()
        newResults = ()
        for row in results:
            newResults = newResults + (tuple(row))
        return jsonify({"id": str(newResults)})
