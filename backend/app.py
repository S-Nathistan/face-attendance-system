from flask import Blueprint
from flask_restful import Api
from resources.Hello import Hello
from resources.Admin import Admin
from resources.All_Employees import AllEmployees
from resources.SearchEmployees import SearchEmployees
from resources.AddEmployee import AddEmployee
from resources.Login import Login
from resources.EmployeeAttendance import EmployeeAttendance
from resources.Upload_photo import UploadPhoto
from resources.DeleteEmployee import DeleteEmployee
from resources.UpdateEmployee import UpdateEmployee
from resources.EmployeeAttendance import EmployeeAttendance
from resources.GetForAttendance import GetForAttendance
from resources.PostToAttendance import PostToAttendance
from resources.ProcessFaceEmbedding import ProcessFaceEmbedding
from resources.processFaceAttendance import ProcessFaceAttendance
from resources.processFaceAttendance import HealthCheck
from resources.GetAllAdmins import GetAllAdmins
from resources.CreateAdmin import CreateAdmin  
from resources.DeleteAdmin import DeleteAdmin  
from resources.UpdateAdmin import UpdateAdmin
from resources.GetEmployeeTempCounts import GetEmployeeTempCounts 
from resources.GetEmployeeTempDetails import GetEmployeeTempDetails
from resources.AddEmployeeTempEmbedding import AddEmployeeTempEmbedding
from resources.EmployeeDetailById import EmployeeDetailById


api_bp = Blueprint('api', __name__)
api = Api(api_bp)

# Route
api.add_resource(Hello, '/Hello')
api.add_resource(Admin, '/admin')
api.add_resource(AllEmployees, '/getall')
api.add_resource(SearchEmployees, '/search')
api.add_resource(AddEmployee, '/add')
api.add_resource(Login, '/login')
api.add_resource(UploadPhoto, '/upload')
api.add_resource(DeleteEmployee, '/delete/<string:emp_id>')
api.add_resource(UpdateEmployee, '/update/<string:emp_id>')
api.add_resource(EmployeeAttendance, '/EmployeeAttendance/<string:emp_id>/<int:year>/<int:month>')
api.add_resource(GetForAttendance, '/getforattendance')
api.add_resource(PostToAttendance, '/posttoattendance')
api.add_resource(ProcessFaceEmbedding, "/process_face")
api.add_resource(ProcessFaceAttendance, "/processfaceattendance")
api.add_resource(HealthCheck, "/health")
api.add_resource(GetAllAdmins, '/getadmins')
api.add_resource(CreateAdmin, '/createadmin')
api.add_resource(DeleteAdmin, '/deleteadmin/<string:admin_id>') 
api.add_resource(UpdateAdmin, '/updateadmin/<string:admin_id>')
api.add_resource(GetEmployeeTempCounts, '/getemployeetempcounts')
api.add_resource(GetEmployeeTempDetails, '/getemployeetempdetails/<string:emp_id>')
api.add_resource(AddEmployeeTempEmbedding, '/AddEmployeeTempEmbedding')
api.add_resource(EmployeeDetailById, '/employee-detail/<string:emp_id>')