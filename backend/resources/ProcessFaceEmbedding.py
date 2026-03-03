from datetime import datetime
from flask_restful import Resource
from flask import jsonify, request
import json
import base64
import config
import cv2
import numpy as np
import tensorflow as tf
import os
import threading
from resources.processFaceAttendance import load_embeddings_cache

cursor = config.conn.cursor()

# Constants
MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets', 'models')
MOBILENET_MODEL_PATH = os.path.join(MODELS_DIR, 'mobilefacenet.tflite')

# Globals
initialization_complete = False
initialization_error = None
mobile_interpreter = None
mobile_input_details = None
mobile_output_details = None

def fix_base64_padding(b64_string):
    return b64_string + '=' * (-len(b64_string) % 4)

def initialize_models():
    global mobile_interpreter, mobile_input_details, mobile_output_details
    global initialization_complete, initialization_error

    try:
        print("Initializing MobileFaceNet model...")

        # Load MobileFaceNet
        mobile_interpreter = tf.lite.Interpreter(model_path=MOBILENET_MODEL_PATH)
        mobile_interpreter.allocate_tensors()
        mobile_input_details = mobile_interpreter.get_input_details()
        mobile_output_details = mobile_interpreter.get_output_details()

        initialization_complete = True
        print("MobileFaceNet model loaded successfully.")

    except Exception as e:
        initialization_error = str(e)
        print(f"Initialization failed: {initialization_error}")

threading.Thread(target=initialize_models, daemon=True).start()

def get_face_embedding(face_img):
    try:
        face_resized = cv2.resize(face_img, (112, 112))
        face_rgb = cv2.cvtColor(face_resized, cv2.COLOR_BGR2RGB)
        face_normalized = (face_rgb.astype('float32') - 127.5) / 128.0
        input_data = np.expand_dims(face_normalized, axis=0)

        mobile_interpreter.set_tensor(mobile_input_details[0]['index'], input_data)
        mobile_interpreter.invoke()
        return mobile_interpreter.get_tensor(mobile_output_details[0]['index'])[0]

    except Exception as e:
        print(f"Embedding error: {e}")
        return None

class ProcessFaceEmbedding(Resource):
    def post(self):
        if not initialization_complete:
            if initialization_error:
                return jsonify({"status": "error", "error": initialization_error}), 500
            return jsonify({"status": "error", "error": "Models still initializing"}), 503

        try:
            data = request.get_json()
            emp_id = data.get("empid")
            image_data = data.get("image")
            additional_images = data.get("additional_images", [])

            if not emp_id or not image_data:
                return jsonify({"status": "fail", "error": "Missing empid or image data"})

            all_images = [image_data] + additional_images  # Combine all images
            embeddings_inserted = 0

            for idx, image_b64 in enumerate(all_images):
                try:
                    # Decode base64 image
                    image_b64 = image_b64.split(',')[-1]
                    image_bytes = base64.b64decode(fix_base64_padding(image_b64))
                    nparr = np.frombuffer(image_bytes, np.uint8)
                    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

                    if img is None:
                        print(f"[Warning] Skipped invalid image at index {idx}")
                        continue

                    # Optionally save each received image for debugging
                    # debug_save_path = os.path.join(os.path.dirname(__file__), f'received_face_for_embedding{idx}.jpg')
                    # cv2.imwrite(debug_save_path, img)

                    # Resize if needed
                    if img.shape[0] != 112 or img.shape[1] != 112:
                        img = cv2.resize(img, (112, 112))

                    # # Optionally save the image after resizing (for debugging)
                    # debug_save_path_after_resize = os.path.join(os.path.dirname(__file__), f'received_face_for_embedding_after_resize_from_backend{idx}.jpg')
                    # cv2.imwrite(debug_save_path_after_resize, img)

                    # Get embedding
                    embedding = get_face_embedding(img)
                    if embedding is None:
                        print(f"[Warning] Embedding generation failed for image {idx}")
                        continue

                    # Normalize embedding
                    
                    

                    # Save embedding
                    embedding_bytes = embedding.tobytes()
                    cursor.execute(
                        """
                        INSERT INTO tblEmbeddings (emp_id, embedding, created_date, emb_no, emb_type)
                        VALUES (?, ?, GETDATE(), ?, ?)
                        """,
                        (emp_id, embedding_bytes, idx + 1, 'base')
                    )
                    embeddings_inserted += 1

                except Exception as inner_e:
                    print(f"[Error] Failed to process image {idx}: {inner_e}")
                    continue

            config.conn.commit()

            if embeddings_inserted == 0:
                return jsonify({"status": "fail", "error": "No valid embeddings generated"})
            
            # print("cache updated successfully")
            load_embeddings_cache()

            return jsonify({
                "status": "success",
                "message": f"{embeddings_inserted} embeddings saved"
            })

        except Exception as e:
            return jsonify({"status": "error", "error": str(e)})

class HealthCheck(Resource):
    def get(self):
        if initialization_complete:
            return {"status": "ready"}, 200
        elif initialization_error:
            return {"status": "error", "error": initialization_error}, 500
        else:
            return {"status": "initializing"}, 202




