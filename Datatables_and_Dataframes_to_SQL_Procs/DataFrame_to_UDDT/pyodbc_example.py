import pandas as pd                 #pip install pandas
import pyodbc                       #pip install pyodbc
import datetime

print("Starting...        " + str(datetime.datetime.now()))

df = pd.DataFrame(
    {'Measurement': ['A - pyobdc', 'B - pyobdc', 'C - pyobdc', 'D - pyobdc', 'E - pyobdc']
    ,'Value': [1, 2, 3, 4, 5]}
    )

tvp = df.values.tolist()

connStr = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=DESKTOP-VPOQODT;DATABASE=NewDatabase;"

#connStr += "Trusted_Connection=yes"    #NTLM/Windows-auth
connStr += "UID=app;PWD=P@$$w0rd;"      #SQL-login

try:
    cnxn = pyodbc.connect(connStr)
    cnxn.autocommit = True

    try:
        cur = cnxn.cursor()

        sql = "{CALL dbo.[usp_Measurements_Upsert] (@LocationCode = ?, @dt_Measurements = ?) }"
        params = (3, tvp)

        print("SQL Starting...    " + str(datetime.datetime.now()))
        cur.execute(sql, params)
        if cnxn.autocommit == False:
            cur.commit()
            print("SQL Committing...  " + str(datetime.datetime.now()))         

        if (len(cur.messages) > 0):
            print(cur.messages)     #returns any console messages (ie PRINT statements)
        cur.nextset()               # required before .fetchall()
        noise = cur.fetchall()      # returns/throws any RAISERROR statements or data from queries
        if (len(noise) > 0):
            print(noise)

    except pyodbc.DatabaseError as de:
        if str(de) != "No results.  Previous SQL was not a query.":
            print("pyodbc.DatabaseError raised")
            print(de)
    except Exception as e:
        print(e)            
    finally:
        cur.close()
except Exception as e:
    print(e)
finally:
    cnxn.close()

print("Completing...      " + str(datetime.datetime.now()))