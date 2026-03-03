import os
import base64
import numpy as np
import cv2
import tensorflow as tf
from flask_restful import Resource
from flask import jsonify, request
from scipy.spatial.distance import cosine
import config
from functools import lru_cache
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from collections import defaultdict
from datetime import datetime


# Constants
MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets', 'models')
MOBILENET_MODEL_PATH = os.path.join(MODELS_DIR, 'mobilefacenet.tflite')
SIMILARITY_THRESHOLD = 0.55

# Global state for initialization
initialization_complete = False
initialization_error = None
embeddings_cache = defaultdict(list)
mobile_interpreter = None
mobile_input_details = None
mobile_output_details = None
cursor = config.conn.cursor()

# Date tracking for cache clearing
last_cache_date = datetime.now().date()


# Clear LRU Cache if the date changed
def clear_cache_if_new_day():
    global last_cache_date
    today = datetime.now().date()
    if today != last_cache_date:
        get_employee_details.cache_clear()
        load_embeddings_cache()
        last_cache_date = today
        print("[Cache] Cleared because new day started.")

# Background initialization function
def initialize_models():
    global mobile_interpreter, mobile_input_details, mobile_output_details
    global initialization_complete, initialization_error

    try:
        start_time = time.time()
        print("Model initialization started...")

        with ThreadPoolExecutor(max_workers=2) as executor:
            futures = {
                "mobile": executor.submit(load_mobilefacenet_model),
                "embeddings": executor.submit(load_embeddings_cache),
            }

            for name, future in futures.items():
                try:
                    result = future.result()
                    if name == "mobile":
                        mobile_interpreter, mobile_input_details, mobile_output_details = result
                except Exception as e:
                    initialization_error = f"{name} model failed: {str(e)}"
                    print(initialization_error)
                    return

        initialization_complete = True
        print(f"Models loaded in {time.time() - start_time:.2f} seconds")
    except Exception as e:
        initialization_error = str(e)
        print(f"[Initialization Error] {initialization_error}")


def load_mobilefacenet_model():
    print("Loading MobileFaceNet model...")
    interpreter = tf.lite.Interpreter(model_path=MOBILENET_MODEL_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    return interpreter, input_details, output_details


def load_embeddings_cache():
    global embeddings_cache
    print("Loading embeddings from database...")

    # First, collect all emp_ids
    cursor.execute("SELECT DISTINCT emp_id FROM tblEmbeddings")
    emp_ids = [row[0] for row in cursor.fetchall()]

    emp_temp_counts = {}
    emp_base_counts = {}

    # Check base and temp counts for all employees
    for emp_id in emp_ids:
        cursor.execute("""
            SELECT emb_type, COUNT(*) FROM tblEmbeddings
            WHERE emp_id = ?
            GROUP BY emb_type
        """, emp_id)
        counts = {row[0]: row[1] for row in cursor.fetchall()}
        emp_base_counts[emp_id] = counts.get('base', 0)
        emp_temp_counts[emp_id] = counts.get('temp', 0)

    # Check the rule: does every employee have exactly 3 temp embeddings?
    all_have_3_temp = all(temp_count == 3 for temp_count in emp_temp_counts.values())

    embeddings_cache.clear()
    total_loaded = 0

    for emp_id in emp_ids:
        if all_have_3_temp:
            # Load both base and temp
            cursor.execute("""
                SELECT embedding FROM tblEmbeddings
                WHERE emp_id = ? AND emb_type IN ('base', 'temp')
                ORDER BY emb_no
            """, emp_id)
        else:
            # Load only base
            cursor.execute("""
                SELECT embedding FROM tblEmbeddings
                WHERE emp_id = ? AND (emb_type = 'base' OR emb_type IS NULL)
                ORDER BY emb_no
            """, emp_id)

        rows = cursor.fetchall()
        embeddings_cache[emp_id] = [np.frombuffer(emb[0], dtype=np.float32) for emb in rows]
        total_loaded += len(embeddings_cache[emp_id])

    if all_have_3_temp:
        print("[Cache] Loaded base + temp embeddings for all employees.")
    else:
        print("[Cache] Loaded ONLY base embeddings for all employees because some are missing 3 temp embeddings.")

    print(f"{total_loaded} embeddings loaded into cache.")


# Compute cosine similarity
def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


# Generate face embedding using MobileFaceNet
def get_face_embedding(face_img):
    try:
        if face_img.shape[0] != 112 or face_img.shape[1] != 112:
            face_img = cv2.resize(face_img, (112, 112))

        face_rgb = cv2.cvtColor(face_img, cv2.COLOR_BGR2RGB)
        face_normalized = (face_rgb.astype('float32') - 127.5) / 128.0
        input_data = np.expand_dims(face_normalized, axis=0)

        mobile_interpreter.set_tensor(mobile_input_details[0]['index'], input_data)
        mobile_interpreter.invoke()
        return mobile_interpreter.get_tensor(mobile_output_details[0]['index'])[0]
    except Exception as e:
        print(f"Embedding error: {e}")
        return None


@lru_cache(maxsize=100)
def get_employee_details(emp_id):
    cursor.execute(
        "SELECT emp_name, position FROM tblEmployees WHERE emp_id = ?", 
        emp_id
    )
    return cursor.fetchone()


def get_last_attendance(emp_id):
    cursor.execute("""
        SELECT TOP 1 att_type FROM tblAttendance 
        WHERE FK_emp_id = ? 
        ORDER BY time_stamp DESC
    """, emp_id)
    result = cursor.fetchone()
    return result[0] if result else None


class ProcessFaceAttendance(Resource):
    def post(self):
        if not initialization_complete:
            if initialization_error:
                return jsonify({"status": "error", "error": initialization_error}), 500
            return jsonify({"status": "error", "error": "Models still initializing"}), 503

        try:

                        # Clear cache if date changed
            clear_cache_if_new_day()

            # Parse and decode image
            data = request.get_json()
            if not data or 'image' not in data:
                return jsonify({"status": "fail", "error": "Image missing"})

            image_data = data['image'].split(',')[-1]
            image_bytes = base64.b64decode(image_data)
            nparr = np.frombuffer(image_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if img is None:
                return jsonify({"status": "fail", "error": "Image decoding failed"})

            # # Save image for debugging
            # debug_img_path = os.path.join(os.path.dirname(__file__), 'received_face.jpg')
            # cv2.imwrite(debug_img_path, img)

            # Resize to 112x112
            if img.shape[0] != 112 or img.shape[1] != 112:
                img = cv2.resize(img, (112, 112))

            # # Save resized image for debugging
            # debug_resized_path = os.path.join(os.path.dirname(__file__), 'received_face_resized.jpg')
            # cv2.imwrite(debug_resized_path, img)

            # Get embedding
            embedding = get_face_embedding(img)
            if embedding is None:
                return jsonify({"status": "fail", "error": "Embedding failed"})

            # Normalize
            embedding = embedding / np.linalg.norm(embedding)

            # Encode the embedding to base64
            embedding_base64 = base64.b64encode(embedding.tobytes()).decode('utf-8')

            grouped_embeddings = embeddings_cache

            matched_id = None
            highest_avg_sim = 0.0

             # Initialize thread pool executor for parallel computation
            with ThreadPoolExecutor(max_workers=4) as executor:
                # Compute similarities for each method concurrently
                futures = {
                    "avg_sim": executor.submit(self.get_best_avg_similarity, embedding, grouped_embeddings),
                    "max_sim": executor.submit(self.get_best_max_similarity, embedding, grouped_embeddings),
                    "knn": executor.submit(self.get_knn_vote, embedding, grouped_embeddings),
                    "centroid": executor.submit(self.get_centroid_match, embedding, grouped_embeddings),
                }

                # Wait for results and process
                results = {name: future.result() for name, future in futures.items()}

                # Log individual results
                votes = defaultdict(int)
                print("\n========== VOTING RESULTS ==========")
                for method, result in results.items():
                    if result:
                        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        print(f"[{timestamp}] [{method}] voted for: {result}")
                        votes[result] += 1

                # Determine the final matched ID by highest votes
                if not votes:
                    return jsonify({"status": "fail", "error": "No match found"})

                # Determine the most voted ID and number of votes
                matched_id, vote_count = max(votes.items(), key=lambda x: x[1])
                print(f"🗳 Final matched_id by voting = {matched_id} (Votes: {vote_count})")

                # Require at least 3 votes to consider as match
                if vote_count < 3:
                    print("[Voting] Not enough agreement among methods. Rejected.")
                    return jsonify({"status": "fail", "error": "No match found"})


            if not matched_id:
                return jsonify({"status": "fail", "error": "No match found"})

            # Fetch employee info
            emp_details = get_employee_details(matched_id)
            if not emp_details:
                return jsonify({"status": "fail", "error": "Employee not found"})

            last_att = get_last_attendance(matched_id)

            return jsonify({
                "status": "success",
                "emp_id": matched_id,
                "emp_name": emp_details[0],
                "similarity": float(highest_avg_sim),
                "last_att": last_att,
                "embedding": embedding_base64  # Send the embedding to frontend
            })

        except Exception as e:
            print(f"[ERROR] {str(e)}")
            return jsonify({"status": "error", "error": str(e)})

        
    def get_best_avg_similarity(self, embedding, grouped_embeddings):
        highest_avg_sim = 0.0
        matched_id = None
        for emp_id, db_emb_list in grouped_embeddings.items():
            sims = [cosine_similarity(embedding, db_emb) for db_emb in db_emb_list]
            avg_sim = np.mean(sims)
            print(f"[avg_sim] emp_id: {emp_id}, avg_sim: {avg_sim:.4f}")
            if avg_sim > highest_avg_sim and avg_sim > SIMILARITY_THRESHOLD:
                highest_avg_sim = avg_sim
                matched_id = emp_id
        return matched_id

    def get_best_max_similarity(self, embedding, grouped_embeddings):
        SIMILARITY_THRESHOLD_max_similarity = 0.60
        highest_max_sim = 0.0
        matched_id = None
        for emp_id, db_emb_list in grouped_embeddings.items():
            sims = [cosine_similarity(embedding, db_emb) for db_emb in db_emb_list]
            max_sim = np.max(sims)
            print(f"[max_sim] emp_id: {emp_id}, max_sim: {max_sim:.4f}")
            if max_sim > highest_max_sim and max_sim > SIMILARITY_THRESHOLD_max_similarity:
                highest_max_sim = max_sim
                matched_id = emp_id
        return matched_id

    def get_knn_vote(self, embedding, grouped_embeddings, top_k=10):
        similarities = []
        for emp_id, db_emb_list in grouped_embeddings.items():
            for db_emb in db_emb_list:
                sim = cosine_similarity(embedding, db_emb)
                similarities.append((emp_id, sim))

        # Sort by similarity and take top_k
        similarities.sort(key=lambda x: x[1], reverse=True)
        top_k_similar = similarities[:top_k]

            # 🧾 Print top_k similarities
        print("[knn] Top K Similarities:")
        for rank, (emp_id, sim) in enumerate(top_k_similar, 1):
            print(f"  {rank}. emp_id: {emp_id}, sim: {sim:.4f}")

        # Tally votes
        vote_counts = defaultdict(int)
        for emp_id, _ in top_k_similar:
            vote_counts[emp_id] += 1

        return max(vote_counts.items(), key=lambda x: x[1])[0]

    def get_centroid_match(self, embedding, grouped_embeddings):
        # Calculate centroids
        centroids = {emp_id: np.mean(emb_list, axis=0) for emp_id, emb_list in grouped_embeddings.items()}
        highest_sim = 0.0
        matched_id = None
        for emp_id, centroid in centroids.items():
            sim = cosine_similarity(embedding, centroid)
            print(f"[sim] emp_id: {emp_id}, sim: {sim:.4f}")
            if sim > highest_sim and sim > SIMILARITY_THRESHOLD:
                highest_sim = sim
                matched_id = emp_id
        return matched_id
   


class HealthCheck(Resource):
    def get(self):
        if initialization_complete:
            return {"status": "ready"}, 200
        elif initialization_error:
            return {"status": "error", "error": initialization_error}, 500
        else:
            return {"status": "initializing"}, 202


# Start initialization in background thread
initialization_thread = threading.Thread(target=initialize_models, daemon=True)
initialization_thread.start()
