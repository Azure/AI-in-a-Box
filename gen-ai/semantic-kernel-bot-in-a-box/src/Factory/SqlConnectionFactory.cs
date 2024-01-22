using Microsoft.Data.SqlClient;

namespace Microsoft.BotBuilderSamples
{
    public class SqlConnectionFactory
    {
        private string _connectionString;
        public SqlConnectionFactory(string connectionString)
        {
            _connectionString = connectionString;
        }

        public SqlConnection createConnection()
        {
            return new SqlConnection(_connectionString);
        }
    }
}