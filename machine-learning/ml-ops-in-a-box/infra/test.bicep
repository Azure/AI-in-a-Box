param functionAppName string = 'AzureMLAlertWebhook'

resource functionApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: functionAppName
}

// resource functionAppHost 'Microsoft.Web/sites/host@2022-09-01' existing = {
//   name: 'default'
//   parent: functionApp
// }



// // Default host key
// output defaultHostKey string = functionAppHost.listKeys().functionKeys.default

// // Master key
// output masterKey string = functionAppHost.listKeys().masterKey

// // Addtionally grab the system keys
// output systemKeys object = functionAppHost.listKeys().systemKeys

output keysobject object = listKeys('${functionApp.id}/host/default', functionApp.apiVersion)
output keys string = listKeys('${functionApp.id}/host/default', functionApp.apiVersion).functionKeys.default
output functionkeys object = listKeys('${functionApp.id}/functions/AzureMLAlertHttpTrigger', functionApp.apiVersion)
output functionkeysstring string = listKeys('${functionApp.id}/functions/AzureMLAlertHttpTrigger', functionApp.apiVersion).default
output appid string = functionApp.id

// https://management.azure.com/subscriptions/4b4ea128-f1cf-47ab-8468-4e9e2ece06e6/resourceGroups/webapprafa/providers/Microsoft.Web/sites/AzureMLAlertWebhook/functions/AzureMLAlertHttpTrigger/listKeys?api-version=2023-01-01
//output keys = functionApp.listKeys('2022-09-01').functionKeys.default

// Invoke-AzResourceAction `
// >     -Action listKeys `
// >     -ResourceType 'Microsoft.Web/sites/functions/' `
// >     -ResourceGroupName 'webapprafa' `
// >     -ResourceName "AzureMLAlertWebhook/AzureMLAlertHttpTrigger" `
// >     -Force -debug -verbose
