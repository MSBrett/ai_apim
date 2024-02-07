# APIM and Azure OpenAI landing zone

## Notes
If you need to purge a deleted APIM instance:

az rest --method delete --header "Accept=application/json" -u 'https://management.azure.com/subscriptions/SubscriptionId/providers/Microsoft.ApiManagement/locations/Location/deletedservices/ApimName?api-version=2020-06-01-preview'