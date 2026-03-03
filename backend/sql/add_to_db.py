import pyodbc as odbccon

conn = odbccon.connect("Driver={SQL Server Native Client 11.0};"
                       "Server=lavan;"
                       "Database=FAS_DB;"
                       "Trusted_Connection=yes;"
                       )
cursor = conn.cursor()

user_id = input("Enter Employee ID : ")
name = input("Enter name : ")
bg = input("Enter blood group : ")
dob = input("Enter date of birth (yyyy-mm-dd): ")
phone_number = input("Enter phone number : ")
address = input("Enter address : ")
query = f"insert into tblEmployees(emp_id,emp_name,emp_bg,emp_dob,emp_phone_number,emp_address) values('{user_id}','{name}' , '{bg}','{dob}','{phone_number}','{address}');"
cursor.execute(query)
cursor.commit()

print("\nRecords\n========\n")

query2 = "select * from tblEmployees"
cursor.execute(query2)

for row in cursor:
    print("row = %r" % (row,))
