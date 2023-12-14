using './main.bicep'

param resourceLocation = 'your-location'
param resourceGroupName = 'your-resource-group-name'
param prefix = 'your-prefix'
param uniqueSuffix = 'your-unique-suffix'
param spObjectId = 'your-service-principal-object-id'

param kvKeyPermissions = [
    'all'
    'create'
    'delete'
    'get'
    'update'
    'list'
    'purge'
]

param kvSecretPermissions = [
    'all'
    'set'
    'get'
    'delete'
    'purge'
]
