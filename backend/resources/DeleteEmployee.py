from flask_restful import Resource
from flask import jsonify
import config
from resources.processFaceAttendance import load_embeddings_cache

cursor = config.conn.cursor()

class DeleteEmployee(Resource):
    def delete(self, emp_id):
        try:
            # Check if the employee exists
            cursor.execute("SELECT * FROM tblEmployees WHERE emp_id = ?", (emp_id,))
            if not cursor.fetchone():
                return jsonify({'status': 'error', 'message': 'Employee not found'})

            # Step 1: Delete embeddings (child)
            cursor.execute("DELETE FROM tblEmbeddings WHERE emp_id = ?", (emp_id,))

            # Step 2: Delete attendance (child)
            cursor.execute("DELETE FROM tblAttendance WHERE FK_emp_id = ?", (emp_id,))

            # Step 3: Delete from Employees (parent)
            cursor.execute("DELETE FROM tblEmployees WHERE emp_id = ?", (emp_id,))
            config.conn.commit()

            load_embeddings_cache()

            return jsonify({'status': 'success', 'message': f'Employee {emp_id} deleted'})

        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)})

