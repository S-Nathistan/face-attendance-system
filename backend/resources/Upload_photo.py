from flask import Flask, request
from flask_restful import Resource
import json
import config

cursor = config.conn.cursor()

class UploadPhoto(Resource):

    def post(self):
        print('upload function called')
        file = request.files['image']
        if file:
            #  file.save('C:\\Users\\User\\Downloads\\Application\\new-backend\\image_encoder\\images\\' + file.filename)
             file.save('C:\\Users\\USER\\Desktop\\image_encoder\\' + file.filename)
             
             return 'Image uploaded successfully', 200
        else:
            return 'Failed to upload image', 400


