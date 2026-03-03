from flask_restful import Resource
from flask import jsonify, request
import json
import config

cursor = config.conn.cursor()


class Login(Resource):

    def post(self):
        request_data = request.data
        request_data = json.loads(request_data.decode('utf-8'))
        username = request_data['username']
        password = request_data['password']

        cursor.execute(f"SELECT * FROM tblAdmin where username ='{username}' AND password = '{password}'")
        user = cursor.fetchone()
        '''for row in list(cursor.fetchall()):
            print(row)'''
        if user:
            return jsonify({"status": "success"})
        else:
            return jsonify({"status": "fail"})
        # print(user)
        # return jsonify({"name": "Hi test"})
