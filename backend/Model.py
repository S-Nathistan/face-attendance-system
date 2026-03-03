from flask import jsonify

import config

cursor = config.conn.cursor()


class Employee:
    id = 0
    name = ''

    def __int__(self, emp_id, emp_name):
        self.id = emp_id
        self.name = emp_name

    def __repr__(self):
        return '<id {}>'.format(self.id)

    def serialize(self):
        return {
            'id': self.id,
            'name': self.username,
        }

    def getEmployees(self):
        id_query = f"select emp_id from tblEmployees"
        fetch_id = cursor.execute(id_query).fetchall()
        id_tuple = []
        for i in range(len(fetch_id)):
            id_tuple.append(fetch_id[i][0])

        name_tuple = []
        name_query = f"select emp_name from tblEmployees"
        fetch_name = cursor.execute(name_query).fetchall()
        for i in range(len(fetch_id)):
            name_tuple.append(fetch_name[i][0])

        status_tuple = []
        status_query = f"select att_type from tblEmployees"
        fetch_status = cursor.execute(status_query).fetchall()
        for i in range(len(fetch_id)):
            status_tuple.append(fetch_status[i][0])

        return id_tuple, name_tuple, status_tuple
        # id_query = f"select emp_id, emp_name from tblEmployees"
        # fetch_id = cursor.execute(id_query).fetchall()
        # print(fetch_id)
