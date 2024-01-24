/*region Header
      Module Steps 
      1 - Create SQL Server
      2 - Create SQL Database
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param sqlServerName string
param sqlDatabaseName string

@description('Set the administrator login for the SQL Server')
@secure()
param administratorLogin string
@description('Set the administrator login password for the SQL Server')
@secure()
param administratorLoginPassword string

// Create SQL Server resource
resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: administratorLogin // Set the administrator login for the SQL Server
    administratorLoginPassword: administratorLoginPassword // Set the administrator login password for the SQL Server
  }
}

// Create SQL Database resource
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-11-01-preview' = {
  parent: sqlServer // Set the parent resource to the SQL Server
  name: sqlDatabaseName // Set the name of the SQL Database
  location: location  // Set the location of the SQL Database
}
