/**
 * Created by George on 16.02.2026.
 */

public with sharing class PurchaseToolController {

    @AuraEnabled(Cacheable=true)
    public static Account getAccountData(Id accountId) {
        return [SELECT Id, Name, AccountNumber, Industry FROM Account WHERE Id = :accountId LIMIT 1];
    }

    @AuraEnabled(Cacheable=true)
    public static List<Item__c> getItems(String family, String type, String searchItem) {
        String query = 'SELECT Id, Name, Description__c, Family__c, Type__c, Price__c, Image__c FROM Item__c';
        List<String> filters = new List<String>();

        if (String.isNotBlank(family)) {
            filters.add('Family__c = :family');
        }
        if (String.isNotBlank(type)) {
            filters.add('Type__c = :type');
        }
        if (String.isNotBlank(searchItem)) {
            String likeTerm = '%' + searchItem + '%';
            filters.add('(Name LIKE :likeTerm OR Description__c LIKE :likeTerm)');
        }

        if (!filters.isEmpty()) {
            query += ' WHERE ' + String.join(filters, ' AND ');
        }

        return Database.query(query);
    }

    @AuraEnabled(Cacheable=true)
    public static Boolean isUserManager() {
        return [SELECT IsManager__c FROM User WHERE Id = :UserInfo.getUserId()].IsManager__c;
    }

    @AuraEnabled
    public static String getUnsplashImageUrl(String itemName) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        String apiKey = 'HgGtV_b6waTm1xAYbz2v8cMccrlSF4_wuvTEWwBYDzQ'; //Delete access key from git
        String endpoint = 'https://api.unsplash.com/search/photos?query=' + EncodingUtil.urlEncode(itemName, 'UTF-8') + '&per_page=1';

        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Client-ID ' + apiKey);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> resultsList = (List<Object>) results.get('results');
                if (!resultsList.isEmpty()) {
                    Map<String, Object> firstPhoto = (Map<String, Object>) resultsList[0];
                    Map<String, Object> urls = (Map<String, Object>) firstPhoto.get('urls');
                    return (String) urls.get('regular');
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error calling Unsplash: ' + e.getMessage());
        }
        return null;
    }

    @AuraEnabled
    public static Id createPurchaseItems(Id accountId, List<Id> itemIds) {
        try {
            Purchase__c p = new Purchase__c(
                    ClientId__c = accountId
            );
            insert p;

            List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
            for(Id itemId : itemIds) {
                lines.add(new PurchaseLine__c(
                        PurchaseId__c = p.Id,
                        ItemId__c = itemId,
                        Amount__c = 1
                ));
            }

            if(!lines.isEmpty()) {
                insert lines;
            }

            return p.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error during checkout: ' + e.getMessage());
        }
    }
}