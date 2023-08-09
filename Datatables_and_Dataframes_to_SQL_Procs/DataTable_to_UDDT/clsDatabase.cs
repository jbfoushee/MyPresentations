using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;

namespace SQLSatDataTableDemo
{
    class clsDatabase
    {
        private readonly string _datasource;
        private readonly string _database;
        private SqlConnection _dbConnection;

        public clsDatabase(string DataSource, string Database)
        {
            _datasource = DataSource;
            _database = Database;
            _dbConnection = new SqlConnection();
        }
        
        private void EnsureConnection()
        {
            if (this._dbConnection.State != ConnectionState.Open)
            {
                string connectionString = "server=" + _datasource + ";database=" + _database + ";UID=app;PWD=P@$$w0rd;";
                _dbConnection = new SqlConnection(connectionString);
                _dbConnection.Open();
            }
        }

        public void UpsertMesaurements(int LocationCode, DataTable Measurements)
        {

            var parameters = new List<SqlParameter>
                {
                    new SqlParameter {ParameterName = "@LocationCode", SqlDbType = SqlDbType.Int, Value = LocationCode},
                    new SqlParameter {ParameterName = "@dt_Measurements", Value = Measurements}
                };

            string procName = "[dbo].[usp_Measurements_Upsert]";

            EnsureConnection();

            using (SqlCommand _cmd = new SqlCommand(procName, _dbConnection))
            {
                _cmd.CommandType = CommandType.StoredProcedure;
                _cmd.Parameters.AddRange(parameters.ToArray());
                _cmd.ExecuteNonQuery();
            }
        }
        
    }
}
