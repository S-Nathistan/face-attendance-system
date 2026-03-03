import pyodbc as odbc_con
'''
conn = odbc_con.connect("Driver={SQL Server Native Client 11.0};"
                        "Server=lavan;"
                        "Database=FAS_DB;"
                        "Trusted_Connection=yes;"
                        ) '''

conn = odbc_con.connect("Driver={SQL Server Native Client 11.0};"
                       "Server=OYSLANS-UCHHPKR;" 
                       "Database=FAS_DB;"
                       "Trusted_Connection=yes;"
                       )


COMPRESS_LEVEL = 6  # Default is 6 (1-9, higher is more compression)
COMPRESS_MIN_SIZE = 500  # Don't compress responses smaller than 500 bytes
