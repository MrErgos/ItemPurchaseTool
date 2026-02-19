/**
 * Created by George on 19.02.2026.
 */

@IsTest
private class PurchaseToolTest {

    @TestSetup
    static void setup() {
        Account testAcc = new Account(
                Name = 'Test Account',
                AccountNumber = '123',
                Industry = 'Technology');
        insert testAcc;

        List<Item__c> items = new List<Item__c>();
        items.add(new Item__c(
                Name = 'Item 1',
                Price__c = 1000,
                Type__c = 'ItemType1',
                Family__c = 'ItemFamily1'
        ));
        items.add(new Item__c(
                Name = 'Item 2',
                Price__c = 500,
                Type__c = 'ItemType2',
                Family__c = 'ItemFamily1'
        ));
        insert items;
    }

    @IsTest
    static void getAccountData_ShouldReturnOneAccount() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];

        //when
        Test.startTest();
        Account result = PurchaseToolController.getAccountData(acc.Id);
        Test.stopTest();

        //then
        System.assertEquals('Test Account', result.Name, 'Should return correct account name');
    }

    @IsTest
    static void getItems_ShouldReturnTwoItems() {
        //given
        //when
        Test.startTest();
        List<Item__c> allItems = PurchaseToolController.getItems('', '', '');
        Test.stopTest();

        //then
        System.assertEquals(2, allItems.size(), 'Should return 2 items');
    }

    @IsTest
    static void getItems_WithTypeFilter_ShouldReturnOneItem() {
        //given
        //when
        Test.startTest();
        List<Item__c> type1Items = PurchaseToolController.getItems('', 'ItemType1', '');
        Test.stopTest();

        //then
        System.assertEquals(1, type1Items.size(), 'Should find 1 item in ItemType1');
        System.assertEquals('Item 1', type1Items.get(0).Name, 'Should find Item 1');
    }

    @IsTest
    static void getItems_WithFamilyFilter_ShouldReturnTwoItems() {
        //given
        //when
        Test.startTest();
        List<Item__c> familyItems = PurchaseToolController.getItems('ItemFamily1', '', '');
        Test.stopTest();

        //then
        System.assertEquals(2, familyItems.size(), 'Should find 2 items in ItemFamily1');
    }

    @IsTest
    static void getItems_WithSearchFilter_ShouldReturnOneItem() {
        //given
        //when
        Test.startTest();
        List<Item__c> searchItems = PurchaseToolController.getItems('', '', 'Item 1');
        Test.stopTest();

        //then
        System.assertEquals(1, searchItems.size(), 'Should find 1 item with name Item 1');
        System.assertEquals('Item 1', searchItems.get(0).Name, 'Should find Item 1');
    }

    @IsTest
    static void createPurchaseItems_ShouldCreatePurchaseInDB() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Item__c> items = [SELECT Id FROM Item__c];
        List<Id> itemIds = new List<Id>{items[0].Id, items[1].Id};

        //when
        Test.startTest();
        Id purchaseId = PurchaseToolController.createPurchaseItems(acc.Id, itemIds);
        Test.stopTest();

        // then
        Purchase__c p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];

        System.assertEquals(2, p.TotalItems__c, 'Total items should be 2');
        System.assertEquals(1500, p.GrandTotal__c, 'Grand Total should be 1500');
    }

    @IsTest
    static void triggerOnDelete_DeletePurchaseLine_ShouldDeletePurchases() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id, Price__c FROM Item__c LIMIT 1];

        Id purchaseId = PurchaseToolController.createPurchaseItems(acc.Id, new List<Id>{item.Id});

        //when
        Test.startTest();
        PurchaseLine__c line = [SELECT Id FROM PurchaseLine__c WHERE PurchaseId__c = :purchaseId LIMIT 1];
        delete line;
        Test.stopTest();

        //then
        Purchase__c p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(0, p.TotalItems__c, 'Total items should be 0 after delete');
        System.assertEquals(0, p.GrandTotal__c, 'Grand Total should be 0 after delete');
    }

    @IsTest
    static void isUserManager_ShouldReturnNotNull() {
        //given
        //when
        Test.startTest();
        Boolean isManager = PurchaseToolController.isUserManager();
        Test.stopTest();

        //then
        System.assertNotEquals(null, isManager);
    }

    @IsTest
    static void getUnsplashImageUrl_RequestIsValid_ReturnImageUrlFromJson() {
        //given
        Test.setMock(HttpCalloutMock.class, new UnsplashHttpCalloutMock());

        //when
        Test.startTest();
        String imageUrl = PurchaseToolController.getUnsplashImageUrl('Some item');
        Test.stopTest();

        //then
        System.assertEquals('https://example.com/image.jpg', imageUrl, 'The image URL should match the mock response');
    }
}