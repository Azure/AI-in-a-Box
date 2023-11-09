# Privacy

When you deploy this template, Microsoft is able to identify the installation of the software with the Azure resources that are deployed. Microsoft is able to correlate the Azure resources that are used to support the software. Microsoft collects this information to provide the best experiences with their products and to operate their business. The data is collected and governed by Microsoft's privacy policies, which can be found at [Microsoft Privacy Statement](https://go.microsoft.com/fwlink/?LinkID=824704).

To disable this, simply remove the following section from [deploy-resources.bicep](./Deployment/1_deployment_scripts/deploy-resources.bicep) before deploying the resources to Azure:

```json
@description('create resource with solution accelerator tag ID')
resource resourceId 'Microsoft.Resources/deployments@2020-10-01' = {
  name: 'pid-1b1b8df6-e4d2-5a68-bd35-8d842a935d5c' 
  properties:{
    mode: 'Incremental'
    template:{
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}
```

You can see more information on this at https://docs.microsoft.com/en-us/azure/marketplace/azure-partner-customer-usage-attribution.