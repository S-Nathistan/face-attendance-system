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
                       "Server=OYSSLANS-ANMGDP\\OYSSQLSERVER;"
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
        # if str(e) == ' sent 1011 (unexpected error) keepalive ping timeout; no close frame received':
        #     print('Reconnecting ..')
        # if str(e) == 'received 1005 (no status code [internal]); then sent 1005 (no status code [internal])':
        #     print('Reconnecting ..')


# RECOGNIZE FUNCTION
def recognize_face(message):
    if message == "":
        pass
    elif message == "Sign-in":
        cursor.execute(
            "update [FAS_DB].[dbo].[tblAttendance] set att_type = 'Sign-in' where att_id = (SELECT TOP (1) att_id FROM [FAS_DB].[dbo].[tblAttendance] ORDER BY att_id DESC)")
        cursor.commit()
        print('status recorded in db')
        return {"status": True, "message": "No Face Detected", "data": 3, "lastatt": "", "name": ""}
    elif message == "Sign-out":
        cursor.execute(
            "update [FAS_DB].[dbo].[tblAttendance] set att_type = 'Sign-out' where att_id = (SELECT TOP (1) att_id FROM [FAS_DB].[dbo].[tblAttendance] ORDER BY att_id DESC)")
        cursor.commit()
        print('status recorded in db')
    elif message == "Lunch-in":
        cursor.execute(
            "update [FAS_DB].[dbo].[tblAttendance] set att_type = 'Lunch-in' where att_id = (SELECT TOP (1) att_id FROM [FAS_DB].[dbo].[tblAttendance] ORDER BY att_id DESC)")
        cursor.commit()
        print('status recorded in db')
    elif message == "Lunch-out":
        cursor.execute(
            "update [FAS_DB].[dbo].[tblAttendance] set att_type = 'Lunch-in' where att_id = (SELECT TOP (1) att_id FROM [FAS_DB].[dbo].[tblAttendance] ORDER BY att_id DESC)")
        cursor.commit()
        print('status recorded in db')
    else:
        global imageCounter
        if message:
            print("Image Received ", imageCounter)
            imageCounter += 1
        try:
            # Converting image
            unknown_picture = face_recognition.load_image_file(io.BytesIO(message))
            print("here1")
            # Get Face Location
            faceCurrentFrame = face_recognition.face_locations(unknown_picture)
            print("here2")

            # Encode Current Frame
            encodeCurrentFrame = face_recognition.face_encodings(unknown_picture, faceCurrentFrame)
            print("here3")

            if not len(encodeCurrentFrame) > 0:
                print("here4")
                print('No face in screen bro')
                return {"status": False, "message": "No Face Detected", "data": 0, "lastatt": "", "name": ""}

            global counter
            global id

            for encodeFace, faceLocation in zip(encodeCurrentFrame, faceCurrentFrame):
                matches = face_recognition.compare_faces(encodeListKnown, encodeFace)
                faceDis = face_recognition.face_distance(encodeListKnown, encodeFace)

                matchIndex = np.argmin(faceDis)  # get minimum index nearly to 0

                # if matches.count(True) == 0:
                # counter = 3
                # print("not recognized")
                # return {"status": True, "message": "No Face Detected", "data": 4, "id": "", "name": ""}

                if matches[matchIndex]:
                    id = studentsIds[matchIndex]
                    print("here5 match found")
                    if counter == 0:
                        counter = 1
                        print("here counter =1")

            if counter != 0:
                print("here6")
                # if counter > 2:
                #     counter = 0
                #     print('no face')
                #     return {"status": True, "message": "No Face Detected", "data": 3, "id": id, "name": ""}

                if counter == 1:
                    print("here7")
                    # Getting specific user data
                    userRecord = cursor.execute(f"select * from [FAS_DB].[dbo].[tblEmployees] where emp_id='{id}'")
                    user = userRecord.fetchone()
                    print("Detected : ", user[2])
                    print(user)
                    total = (datetime.now() - user[7])
                    if total.total_seconds() < 20:
                        print("here8")
                        print(total.total_seconds())
                        # counter = 3
                        print("already marked")
                        # return {"status": True, "message": "", "data": 1}
                        return {"status": True, "message": "Already marked", "data": 1, "id": "", "name": "",
                                "lastatt": ""}

                    else:
                        print("here9")
                        currentDateObj = datetime.now().strftime("%m-%d-%y %H:%M:%S")
                        print(currentDateObj)
                        cursor.execute(
                            f"insert into [FAS_DB].[dbo].[tblAttendance](FK_emp_id, time_stamp) values ('{id}','{currentDateObj}')")
                        cursor.commit()
                        print('image recorded in db')

                        # counter += 1
                        print("success")

                        # Getting last attendance status from STATUS TABLE
                        attendanceRecord = cursor.execute(f"SELECT TOP (1) last_status FROM tblLastStatus where "
                                                          f"FK_emp_id='{id}' ORDER BY id DESC")
                        lastAttendance = attendanceRecord.fetchall()
                        print(lastAttendance)
                        # if not lastAttendance:
                        #     return {"status": True, "message": "Recognition successful", "data": 2, "id": id,
                        #             "name": user[2],
                        #             "lastatt": None}
                        # else:
                        print("here10")
                        return {"status": True, "message": "Recognition successful", "data": 2, "id": id, "name": user[2], "lastatt": lastAttendance[0][0]}
                # counter += 1
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

    # confirmation
