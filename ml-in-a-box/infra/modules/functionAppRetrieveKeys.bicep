param functionname string
param functionAppName string

resource azfunctionsite 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionname
}

output functionAppUrl string = 'https://${azfunctionsite.properties.defaultHostName}/api/${toLower(functionAppName)}?code=${listKeys('${azfunctionsite.id}/functions/${functionAppName}', azfunctionsite.apiVersion).default}'
