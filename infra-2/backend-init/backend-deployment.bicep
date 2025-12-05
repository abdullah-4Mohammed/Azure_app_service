@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageAccountType string 
param storageAccountName string
param blobContainerNameShared string
// param blobContainerNameCommon string
// param blobContainerNameEnvironment string
@description('Location for all resources.')
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties:{
    allowBlobPublicAccess: false
  }
}

// resource storageAccountContainerCommon 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
//   name: '${storageAccountName}/default/${blobContainerNameCommon}'
//   dependsOn: [
//     storageAccount
//   ]
// }

// resource storageAccountContainerEnvironment 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
//   name: '${storageAccountName}/default/${blobContainerNameEnvironment}'
//   dependsOn: [
//     storageAccount
//   ]
// }

resource storageAccountContainerShared 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${storageAccountName}/default/${blobContainerNameShared}'
  dependsOn: [
    storageAccount
  ]
}

resource storaceAccountRetentionProperties 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    isVersioningEnabled: true
    containerDeleteRetentionPolicy: {
      allowPermanentDelete: false
      days: 180
      enabled: false
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      days: 180
      enabled: false
    }
    restorePolicy: {
      days: 30
      enabled: false
    }
  }
}
