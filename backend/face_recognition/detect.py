import asyncio
import io
import json
import pickle
from datetime import datetime
import face_recognition
import numpy as np
import websockets
import pyodbc as odbccon

conn = odbccon.connect("Driver={SQL Server Native Client 11.0};"
                       "Server=DESKTOP-QIDMP66\OYSSQLSERVER;"  
                       "Database=FAS_DB;"
                       "Trusted_Connection=yes;"
                       )
cursor = conn.cursor()

file = open("../image_encoder/EncodedFile.p", "rb")
encodeListKnownWithIds = pickle.load(file)
file.close()
encodeListKnown, studentsIds = encodeListKnownWithIds

id = 0
counter = 0
imageCounter = 1


# WEBSOCKET
async def websocket_handler(websocket, path):
    try:
        async for message in websocket:
            response = recognize_face(message)
            await websocket.send(json.dumps(response))
    except Exception as e:
        print(e)
        if str(e) == ' sent 1011 (unexpected error) keepalive ping timeout; no close frame received':
            print('Waiting  ..')
        if str(e) == 'received 1005 (no status code [internal]); then sent 1005 (no status code [internal])':
            print('Waiting ..')


# RECOGNIZE FUNCTION
def recognize_face(message):
    if message == "":

        pass

    elif message == "Sign-in":
        cursor.execute(
            "update [FAS_DBnw].[dbo].[tblAttendance] set att_type = 'Sign-in' where att_id = (SELECT TOP (1) att_id "
            "FROM [FAS_DBnw].[dbo].[tblAttendance] ORDER BY att_id DESC)")
        cursor.commit()
        print('Status recorded in db')

        return {"status": True, "message": "No Face Detected", "data": 3, "lastatt": "", "name": ""}
    elif message == "Sign-out":
        cursor.execute(
            "update [FAS_DBnw].[dbo].[tblAttendance] set att_type = 'Sign-out' where att_id = (SELECT TOP (1) att_id "
            "FROM [FAS_DBnw].[dbo].[tblAttendance] ORDER BY att_id DESC)")
        cursor.commit()
        print('Status recorded in db')

    elif message == "Lunch-in":
        cursor.execute(
            "update [FAS_DBnw].[dbo].[tblAttendance] set att_type = 'Lunch-in' where att_id = (SELECT TOP (1) att_id "
            "FROM [FAS_DBnw].[dbo].[tblAttendance] ORDER BY att_id DESC)")
        cursor.commit()
        print('Status recorded in db')

    elif message == "Lunch-out":
        cursor.execute(
            "update [FAS_DBnw].[dbo].[tblAttendance] set att_type = 'Lunch-out' where att_id = (SELECT TOP (1) att_id "
            "FROM [FAS_DBnw].[dbo].[tblAttendance] ORDER BY att_id DESC)")
        cursor.commit()
        print('Status recorded in db')

    else:
        global imageCounter
        if message:
            print('Scanning ..')
            imageCounter += 1
        try:
            # Converting image
            unknown_picture = face_recognition.load_image_file(io.BytesIO(message))

            # Get Face Location
            faceCurrentFrame = face_recognition.face_locations(unknown_picture)

            # Encode Current Frame
            encodeCurrentFrame = face_recognition.face_encodings(unknown_picture, faceCurrentFrame)

            if not len(encodeCurrentFrame) > 0:
                print('No face Detected')
                return {"status": False, "message": "No Face Detected", "data": 0, "lastatt": "", "name": ""}

            global counter
            global id

            for encodeFace, faceLocation in zip(encodeCurrentFrame, faceCurrentFrame):
                matches = face_recognition.compare_faces(encodeListKnown, encodeFace)
                faceDis = face_recognition.face_distance(encodeListKnown, encodeFace)

                matchIndex = np.argmin(faceDis)  # get minimum index nearly to 0

                if matches[matchIndex]:
                    id = studentsIds[matchIndex]
                    if counter == 0:
                        counter = 1
                        

            if counter != 0:

                if counter == 1:
                    
                    # Getting specific user data
                    user_record = cursor.execute(f"select * from [FAS_DB].[dbo].[tblEmployees] where emp_id='{id}'")
                    user = user_record.fetchone()
                    print("Detected : ", user[2])

                    total = (datetime.now() - user[7])
                    if total.total_seconds() < 120:
                        print("Already Marked")
                        print(total.total_seconds())

                        return {"status": True, "message": "Already marked", "data": 1, "id": "", "name": "",
                                "lastatt": ""}

                    else:
                        current_date_obj = datetime.now().strftime("%m-%d-%y %H:%M:%S")
                        cursor.execute(
                            f"insert into [FAS_DBnw].[dbo].[tblAttendance](FK_emp_id, time_stamp) values ('{id}','{current_date_obj}')")
                        cursor.commit()
                        print('Detection recorded in db')

                        # Getting last attendance status from STATUS TABLE
                        attendance_record = cursor.execute(f"SELECT TOP (1) att_type FROM tblEmployees where "
                                                           f"emp_id='{id}' ORDER BY id DESC")
                        last_attendance = attendance_record.fetchall()
                        
                        return {"status": True, "message": "Recognition successful", "data": 2, "id": id,
                                "name": user[2], "lastatt": last_attendance[0][0]}

                counter = 0
        except Exception as e:
            return e


if __name__ == '__main__':
    print("\n+==================+\n|  SERVER STARTED  |\n+==================+\n")
    loop = asyncio.get_event_loop()
    loop.run_until_complete(
        websockets.serve(websocket_handler, "localhost", 8765)
    )
    loop.run_forever()

