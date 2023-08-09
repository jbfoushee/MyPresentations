import pandas as pd                 #pip install pandas
import pytds                        #pip install python-tds
from pytds.login import NtlmAuth    #pip install ntlm-auth
import random, string
import datetime

print("Starting...        " + str(datetime.datetime.now()))

df = pd.DataFrame({'Measurement': ['F - pytds', 'G - pytds', 'H - pytds', 'I - pytds', 'J - pytds'], 'Value': [6, 7, 8, 9, 10]})

tvp = pytds.TableValuedParam(
        type_name = 'dbo.Type_Measurements'
        , columns = (
            pytds.Column(type=pytds.tds_types.VarCharType(size=10))
            , pytds.Column(type=pytds.tds_types.IntType())
            )
        , rows = df.values.tolist()
    )

try:
    ## NTLM/Windows-auth
    ## -----------------
    #ntlm = NtlmAuth(user_name="DOMAIN\USERNAME", password=input("password?\n"))
    #cnxn = pydts.connect(dsn='DESKTOP-VPOQODT', database='NewDatabase', auth=ntlm, autocommit=True)

    ## SQL-login
    ## -----------------
    cnxn = pytds.connect(dsn='DESKTOP-VPOQODT', database="NewDatabase", user="app", password="P@$$w0rd", autocommit=True)

    try:
        cur = cnxn.cursor()
        print("SQL Starting...    " + str(datetime.datetime.now()))
        cur.execute('EXECUTE dbo.[usp_Measurements_Upsert] @LocationCode=%s, @dt_Measurements=%s', (4, tvp) )

        if cnxn.autocommit == False:
            cur.commit()
            print("SQL Committing...  " + str(datetime.datetime.now()))
        
        if (len(cur.messages) > 0):
            print(cur.messages)     # returns any console messages (ie PRINT statements)
        cur.nextset()               # required before .fetchall()
        noise = cur.fetchall()      # returns/throws any RAISERROR statements or data from queries
        if (len(noise) > 0):
            print(noise)

    except pytds.DatabaseError as de:
        if str(de) != "Previous statement didn't produce any results":
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