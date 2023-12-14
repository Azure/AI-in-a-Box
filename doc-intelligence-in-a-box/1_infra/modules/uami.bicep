/*region Header
      Module Steps 
      1 - Create User-Assignment Managed Identity used to execute deployment scripts
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param deploymentScriptUAMIName string

//https://docs.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities
//1. User-Assignment Managed Identity used to execute deployment scripts
resource r_UAMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: deploymentScriptUAMIName
  location: resourceLocation
  tags: {
    SA : 'Azure Safety Form Processing Automation'
  }
}

output uamiId string = r_UAMI.id
output uamiClientid string = r_UAMI.properties.clientId
output uamiName string = r_UAMI.name
output uamiPrincipleId string = r_UAMI.properties.principalId
