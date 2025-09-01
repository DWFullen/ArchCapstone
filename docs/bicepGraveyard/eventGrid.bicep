/* resource eventGridSystemTopic 'Microsoft.EventGrid/systemTopics@2025-02-15' = {
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.eventGridDomainsTopics}'
  location: location
  tags: union(tags, {
    azdServiceName: 'nist-eventgrid-systemtopic'
    zLocation: zLocation
    azSubscription: azureSubscription
    applicationName: applicationName
    devEnvironmentName: devEnvironmentName
    applicationVersion: applicationVersion
  })
  properties: {
    source: storageAccount.id
    topicType: 'microsoft.storage.storageaccounts'
  }
}
 */
/* resource eventGridSystemTopicAntimalwareSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2025-02-15' = {
  parent: eventGridSystemTopic
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.antiMalwareSubscription}'
  properties: {
    destination: {
      properties: {
        //endpointUrl: 'https://your-storage-event-handler-endpoint' // Replace with your Azure Function or Logic App endpoint
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
        //azureActiveDirectoryTenantId: '33e01921-4d64-4f8c-a055-5bdaffd5e33d'
        //azureActiveDirectoryApplicationIdOrUri: 'f1f8da5f-609a-401d-85b2-d498116b7265'
      }
      endpointType: 'WebHook'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      advancedFilters: [
        {
          values: [
            'BlockBlob'
          ]
          operatorType: 'StringContains'
          key: 'data.blobType'
        }
      ]
    }
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}
 */
// This file is deprecated and kept for reference only.
