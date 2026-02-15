/**
 * Created by George on 15.02.2026.
 */

trigger PurchaseLineTrigger on PurchaseLine__c (after insert, after update, after delete, after undelete) {
    Set<Id> purchaseIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (PurchaseLine__c pl : Trigger.new) {
            if (pl.PurchaseId__c != null) {
                purchaseIds.add(pl.PurchaseId__c);
            }
        }
    }

    if (Trigger.isDelete) {
        for (PurchaseLine__c pl : Trigger.old) {
            if (pl.PurchaseId__c != null) {
                purchaseIds.add(pl.PurchaseId__c);
            }
        }
    }

    if (!purchaseIds.isEmpty()) {
        List<Purchase__c> purchasesToUpdate = [
                SELECT Id, TotalItems__c, GrandTotal__c,
                (SELECT Amount__c, UnitCost__c FROM Purchase_Lines__r)
                FROM Purchase__c
                WHERE Id IN :purchaseIds
        ];

        for (Purchase__c p : purchasesToUpdate) {
            Decimal totalAmount = 0;
            Decimal grandTotal = 0;

            for (PurchaseLine__c pl : p.Purchase_Lines__r) {
                Decimal amount = pl.Amount__c != null ? pl.Amount__c : 0;
                Decimal cost = pl.UnitCost__c != null ? pl.UnitCost__c : 0;

                totalAmount += amount;
                grandTotal += (amount * cost);
            }

            p.TotalItems__c = totalAmount;
            p.GrandTotal__c = grandTotal;
        }

        update purchasesToUpdate;
    }
}