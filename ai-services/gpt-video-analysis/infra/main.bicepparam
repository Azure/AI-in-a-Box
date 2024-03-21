using './main.bicep'

param resourceGroupName = 'your-resource-group-name' // the name of the resource group you created earlier
param resourceLocation = 'your-location' // this must be a region where GPT-4 Turbo with Vision is available
param resourceLocationCV = 'your-location' // thhis must be a region where Computer Vision with Image Analysis 4.0 is available
param prefix = 'your-prefix' // a few alpha characters to make your resources unique
param suffix = 'your-unique-suffix' // a few more alphanumeric characters to make your resources unique
param spObjectId = 'your-service-principal-object-id' // the object id of the service principal you created earlier

