/*region Header
      Module Steps 
      1 - Create User-Assignment Managed Identity used to execute deployment scripts
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param identityName string
param location string = resourceGroup().location

//https://docs.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities
//1. User-Assignment Managed Identity used to execute deployment scripts
resource azidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: identityName
  location: location
}

output identityid string = azidentity.id
output clientId string = azidentity.properties.clientId
output principalId string = azidentity.properties.principalId
