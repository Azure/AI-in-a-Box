using System;
using System.ComponentModel;
using Microsoft.Data.SqlClient;
using Microsoft.SemanticKernel;
using Microsoft.BotBuilderSamples;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using System.Threading.Tasks;

namespace Plugins;

public class SQLPlugin
{
    private readonly SqlConnectionFactory _sqlConnectionFactory;
    private ITurnContext<IMessageActivity> _turnContext;
    public SQLPlugin(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, SqlConnectionFactory sqlConnectionFactory) 
    {
        _turnContext = turnContext;
        _sqlConnectionFactory = sqlConnectionFactory;
    }




    [KernelFunction, Description("Obtain the table names in AdventureWorksLT, which contains customer and sales data. Always run this before running other queries instead of assuming the user mentioned the correct name. Remember the salesperson information is contained in the Customer table.")]
    public async Task<string> GetTables() {
        await _turnContext.SendActivityAsync($"Getting tables...");
        return QueryAsCSV($"SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES;");
    }



    [KernelFunction, Description("Obtain the database schema for a table in AdventureWorksLT.")]
    public async Task<string> GetSchema(
        [Description("The table to get the schema for. Do not include the schema name.")] string tableName
    ) 
    {
        await _turnContext.SendActivityAsync($"Getting schema for table \"{tableName}\"...");
        return QueryAsCSV($"SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '{tableName}';");
    }



    [KernelFunction, Description("Run SQL against the AdventureWorksLT database")]
    public async Task<string> RunQuery(
        [Description("The query to run on SQL Server. When referencing tables, make sure to add the schema names.")] string query
    )
    {
        await _turnContext.SendActivityAsync($"Running query...");
        return QueryAsCSV(query);
    }




    private string QueryAsCSV(string query) 
    {
        var output = "[DATABASE RESULTS] \n";
        using (SqlConnection connection = _sqlConnectionFactory.createConnection())
        {
            SqlCommand command = new SqlCommand(query, connection);
            connection.Open();
            SqlDataReader reader = command.ExecuteReader();
            try
            {
                for (int i = 0; i < reader.FieldCount; i++) {
                    output += reader.GetName(i);
                    if (i < reader.FieldCount - 1) 
                        output += ",";
                }
                output += "\n";
                while (reader.Read())
                {
                    for (int i = 0; i < reader.FieldCount; i++) {
                        var columnName = reader.GetName(i);
                        output += reader[columnName].ToString();
                        if (i < reader.FieldCount - 1) 
                            output += ",";
                    }
                    output += "\n";
                }
            } catch (Exception e) {
                Console.WriteLine(e);
            }
            finally
            {
                reader.Close();
            }
        }
        return output;
    }

}