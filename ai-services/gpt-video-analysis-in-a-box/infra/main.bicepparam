using './main.bicep'

// param resourceLocation = 'your-location'
// param resourceGroupName = 'your-resource-group-name'
// param prefix = 'your-prefix'
// param suffix = 'your-unique-suffix'
// param spObjectId = 'your-service-principal-object-id'


param resourceGroupName  = 'jhaoai32jh'
param resourceLocation  = 'westus' // as of 2024-01-23, GPT4V is only available in westus in the US, storage account must be in the same region as OpenAI resource
param resourceLocationCV  = 'eastus' // as of 2024-01-23, CV with image analysis 4.0 is only available in eastus in the US@description('Your Object ID')
param spObjectId   = '95d57743-ea03-4a76-a91f-02834c567119' //This is your own users Object ID
param prefix  = 'vk'
param suffix  = 'sk'

