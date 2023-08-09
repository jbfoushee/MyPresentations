using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Reflection;

namespace SQLSatDataTableDemo
{
    static class Utilities
    {
        public static DataTable ToDataTable_ver1<T>(this IList<T> list) where T : class
        {
            var dt = new DataTable();

            Type t = typeof(T);
            var properties = t.GetProperties(BindingFlags.Instance | BindingFlags.Public |  BindingFlags.NonPublic);

            foreach (var property in properties)
            {
                dt.Columns.Add(property.Name, property.PropertyType);
            }

            foreach (var item in list)
            {
                dt.Rows.Add(properties.Select(p => p.GetValue(item, null)).ToArray());
            }

            return dt;
        }

        public static void GetProperties<T>() where T : class
        {
            Type t = typeof(T);
            var properties = t.GetProperties(BindingFlags.Default);

            properties = t.GetProperties(BindingFlags.NonPublic | BindingFlags.Public);
            properties = t.GetProperties(BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.DeclaredOnly);
            properties = t.GetProperties(BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance);
            properties = t.GetProperties(BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly);
            properties = t.GetProperties(BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
            properties = t.GetProperties(BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static | BindingFlags.DeclaredOnly);
            properties = t.GetProperties(BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance);
            properties = t.GetProperties(BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance | BindingFlags.DeclaredOnly);


            //https://learn.microsoft.com/en-us/dotnet/api/system.type.getproperties?view=net-7.0
            //https://learn.microsoft.com/en-us/dotnet/api/system.reflection.bindingflags?view=net-7.0

        }

        public static DataTable ToDataTable_ver2(IList<clsMeasure> list)
        {
            var dt = new DataTable();

            dt.Columns.Add("MeasureName", typeof(string));
            dt.Columns.Add("Value", typeof(int));

            foreach (var item in list)
            {
                DataRow dr = dt.NewRow();
                dr["MeasureName"] = item.MeasureName;
                dr["Value"] = item.Value;

                dt.Rows.Add(dr);
            }

            return dt;
        }
    }
}
