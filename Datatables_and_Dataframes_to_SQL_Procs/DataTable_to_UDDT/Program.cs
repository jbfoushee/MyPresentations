using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace SQLSatDataTableDemo
{
    class Program
    {
        static void Main()
        {
            Console.WriteLine("Hello World!");

            //it was determined from an appsettings.json that this location is # 2...
            //I deliberately did not implement to avoid unnecessary code libraries
            var locationId = 2;

            //build a list of class objects...
            List<clsMeasure> lstMeasures = new List<clsMeasure> { };
            for (int i = 75; i < 80; i++)
            {
                lstMeasures.Add(new clsMeasure(Convert.ToChar(i).ToString() + " - C#.NET", i-64));
            }

            //transform the list of objects into a DataTable
            DataTable dtReturn = Utilities.ToDataTable_ver1(lstMeasures);
            // DataTable dtReturn = Utilities.ToDataTable_ver2(lstMeasures);

            //let's dive into the GetProperties Bindings enums...
            Utilities.GetProperties<clsArbitrary>();

            //Upsert the rows
            UpsertDataTable(locationId, dtReturn);
            Console.WriteLine("Rows added!");
            Console.ReadLine();

        }

        private static void UpsertDataTable(int Location, DataTable results)
        {
            clsDatabase theDatabase = new clsDatabase("DESKTOP-VPOQODT", "NewDatabase");
            theDatabase.UpsertMesaurements(Location, results);
        }


    }
}
