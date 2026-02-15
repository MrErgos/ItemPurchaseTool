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
            query += 'WHERE ' + String.join(filters, ' AND ');
        }

        return Database.query(query);
    }
}