/*/
      1 - Create User-Assignment Managed Identity used to execute deployment scripts
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param uamiResourceName string

//https://docs.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities
//1. User-Assignment Managed Identity used to execute deployment scripts
resource r_UAMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiResourceName
  location: resourceLocation
  
}

output uamiId string = r_UAMI.id
output uamiClientid string = r_UAMI.properties.clientId
output uamiName string = r_UAMI.name
output uamiPrincipleId string = r_UAMI.properties.principalId
