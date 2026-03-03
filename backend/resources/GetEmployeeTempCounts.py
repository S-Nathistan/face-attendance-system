from flask_restful import Resource
from flask import jsonify
import config


class GetEmployeeTempCounts(Resource):
    def get(self):
        try:
            cursor = config.conn.cursor()
            cursor.execute("""
                SELECT e.emp_id, 
                    COUNT(CASE WHEN em.emb_type = 'temp' THEN 1 END) AS temp_count
                FROM tblEmployees e
                LEFT JOIN tblEmbeddings em ON e.emp_id = em.emp_id
                GROUP BY e.emp_id
            """)
            rows = cursor.fetchall()

            emp_temp_list = []
            for row in rows:
                emp_temp_list.append({
                    "emp_id": row[0],      
                    "temp_count": row[1]   
                })

            return jsonify(emp_temp_list)
        except Exception as e:
            return jsonify({"error": str(e)})
