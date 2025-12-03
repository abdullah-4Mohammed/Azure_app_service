// // =========== storage.bicep ===========
// // targetScope = 'resourceGroup' - not needed since it is the default value

// param storageAccountName string
// param location string 

// resource stg 'Microsoft.Storage/storageAccounts@2021-02-01' = {
//   name: storageAccountName
//   location: location
//   sku: {
//     name: 'Standard_LRS'
//   }
//   kind: 'StorageV2'
// }

// resource stg_blob 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
//   parent: stg
//   name: 'default'
//   properties: {
//     cors: {
//       corsRules:[{
//         allowedOrigins: ['*']
//         allowedMethods: [
//           'GET'
//           'PUT'
//           'HEAD'
//           'DELETE'
//         ]
//         allowedHeaders: ['*']
//         exposedHeaders: ['*']
//         maxAgeInSeconds: 86400
//       }]
//     }
//   }
// }

// resource stg_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
//   parent: stg_blob
//   name: 'platformstate'
//   properties: {
//     publicAccess: 'None'
//   }
// }

// output storageAccountName string = stg.name
// output storageAccountId string = stg.id
