from flask_restful import Resource
from flask import jsonify
from datetime import datetime, timedelta
import config

class EmployeeAttendance(Resource):
    def get(self, emp_id, year, month):
        cursor = config.conn.cursor()

        query = '''
        SELECT 
            time_stamp,
            att_type
        FROM tblAttendance
        WHERE FK_emp_id = ?
            AND YEAR(time_stamp) = ?
            AND MONTH(time_stamp) = ?
        ORDER BY time_stamp ASC
        '''
        cursor.execute(query, emp_id, year, month)
        rows = cursor.fetchall()

        results = []
        full_day_count = 0
        half_day_count = 0
        unfinished_session = None

        for row in rows:
            date_time = row.time_stamp  # full datetime
            typ = row.att_type

            if typ == 'Sign-in' and unfinished_session is None:
                unfinished_session = {'signed_in': date_time, 'lunch_out': None, 'lunch_in': None, 'sign_out': None}
            elif typ == 'Lunch-out' and unfinished_session:
                unfinished_session['lunch_out'] = date_time
            elif typ == 'Lunch-in' and unfinished_session:
                unfinished_session['lunch_in'] = date_time
            elif typ == 'Sign-out' and unfinished_session:
                unfinished_session['sign_out'] = date_time

                work_hours = calculate_work_hours(
                    unfinished_session.get('signed_in'),
                    unfinished_session.get('lunch_out'),
                    unfinished_session.get('lunch_in'),
                    unfinished_session.get('sign_out')
                )

                hours_value = work_hours  # Directly use the float value here

                if hours_value >= 8:
                    full_day_count += 1
                elif hours_value >= 4:
                    half_day_count += 1

                results.append({
                    'date': unfinished_session.get('signed_in').strftime('%Y-%m-%d'),
                    'signed_in': unfinished_session.get('signed_in').strftime('%H:%M:%S') if unfinished_session.get('signed_in') else 'N/A',
                    'lunch_out': unfinished_session.get('lunch_out').strftime('%H:%M:%S') if unfinished_session.get('lunch_out') else 'N/A',
                    'lunch_in': unfinished_session.get('lunch_in').strftime('%H:%M:%S') if unfinished_session.get('lunch_in') else 'N/A',
                    'sign_out': unfinished_session.get('sign_out').strftime('%H:%M:%S') if unfinished_session.get('sign_out') else 'N/A',
                    'work_hours': work_hours
                })
                unfinished_session = None  # Reset for next session

        return jsonify({
            'results': results,
            'full_day_count': full_day_count,
            'half_day_count': half_day_count
        })


def calculate_work_hours(sign_in, lunch_out, lunch_in, sign_out):
    try:
        t_sign_in = sign_in if sign_in else None
        t_lunch_out = lunch_out if lunch_out else None
        t_lunch_in = lunch_in if lunch_in else None
        t_sign_out = sign_out if sign_out else None

        if t_sign_in and t_sign_out:
            morning = (t_lunch_out - t_sign_in) if t_lunch_out else (t_sign_out - t_sign_in)
            afternoon = (t_sign_out - t_lunch_in) if t_lunch_out and t_lunch_in else timedelta()

            total = morning + afternoon
            hours = total.total_seconds() / 3600  # Return hours as a float
            return hours  # Return raw number as float
        return 0.0  # Return float zero if data is missing
    except Exception as e:
        print(f"Error calculating work hours: {e}")
        return 0.0  # Return float zero in case of error

