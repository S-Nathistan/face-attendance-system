from datetime import datetime
from flask_restful import Resource
from flask import jsonify, request
import json
import base64
import config
import cv2
import os
import numpy as np
# from resources.processFaceAttendance import load_embeddings_cache


cursor = config.conn.cursor()

user_id = ""
name = ""
bg = ""
dob = ""
phone_number = ""
address = ""

userPrefix = "OYS"
userCount = 1
response = ''

# Function to fix base64 padding
def fix_base64_padding(b64_string):
    """Ensure base64 string is correctly padded."""
    return b64_string + '=' * (-len(b64_string) % 4)

class AddEmployee(Resource):

    def post(self):
        global user_id
        global name
        global bg
        global dob
        global phone_number
        global address
        global response
        global userCount
        global userPrefix


        print('add function called')
        # ===========================
        #   AUTO INCREMENTING ID
        # ===========================
        query2 = f"SELECT SUBSTRING((select top(1) emp_id from tblEmployees where emp_id like 'OYS%' order by id desc), 4,5) AS emp_id"
        cursor.execute(query2)
        result = cursor.fetchone()
        if result:
            userCount = int(result[0])
            userCount += 1
        else:
            # If no employee exists, start with 1
            userCount = 1
        user_id = userPrefix + str(userCount)

        # ===========================
        #   FETCHING REQUEST
        # ===========================

        request_data = request.data
        request_data = json.loads(request_data.decode('utf-8'))
        # user_id = request_data['id']
        print(request_data)
        name = request_data['name']
        bg = request_data['bg']
        address = request_data['address']
        phone_number = request_data['phone']
        position = request_data['position']
        mail = request_data['mail']

        # Handle base64 image and fix padding
        image_data_raw = request_data.get("emp_photo", "")
        if image_data_raw:
            if ',' in image_data_raw:
                image_data_raw = image_data_raw.split(',')[1]  # Remove the header if it exists
            safe_image_data = fix_base64_padding(image_data_raw)
            try:
                imagedata = base64.b64decode(safe_image_data)

                #                 # === SAVE IMAGE FOR DEBUGGING ===
                # npimg = np.frombuffer(imagedata, dtype=np.uint8)
                # img_np = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
                # save_path = os.path.join(os.path.dirname(__file__), 'received_face_for_employeea_add.jpg')
                # cv2.imwrite(save_path, img_np)
                # print(f"Saved image to {save_path}")


            except base64.binascii.Error as e:
                return jsonify([{"status": "fail", "error": "Invalid base64 image data", "details": str(e)}])
        else:
            imagedata = None



        # dob = request_data['date']
        # formattedDate = datetime.strptime(dob, "%d-%m-%Y")
        dateNow = datetime.now()
        for row in list(cursor.fetchall()):
            print(row)
        # if user_id =
        print(request_data)
        print('\n\n\nuserid',user_id)
        # ===========================
        #   ADDING TO DATABASE
        # ===========================

        query = """
        INSERT INTO tblEmployees (emp_id, emp_name, emp_bg, emp_dob, emp_phone_number, emp_address, emp_mail, position, created_date, emp_photo)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, GETDATE(), ?);
        """
        cursor.execute(query, (user_id, name, bg, dateNow, phone_number, address, mail, position, imagedata))
        cursor.commit()
        print("Inserted successfully")

        # load_embeddings_cache()
        return jsonify([{"status": "success", "empid": user_id}])
