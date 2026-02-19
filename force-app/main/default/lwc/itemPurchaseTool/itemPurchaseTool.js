/**
 * Created by George on 16.02.2026.
 */

import { LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAccountData from '@salesforce/apex/PurchaseToolController.getAccountData';
import isUserManager from '@salesforce/apex/PurchaseToolController.isUserManager';
import getItems from '@salesforce/apex/PurchaseToolController.getItems';
import getUnsplashImageUrl from '@salesforce/apex/PurchaseToolController.getUnsplashImageUrl';
import createPurchaseItems from '@salesforce/apex/PurchaseToolController.createPurchaseItems';
import { NavigationMixin } from 'lightning/navigation';

export default class ItemPurchaseTool extends NavigationMixin(LightningElement) {
    @api recordId;
    @track items = [];
    @track isManager = false;
    @track isCreateModalOpen = false;

    @track isDetailsModalOpen = false;
    @track selectedItem = {};
    @track isCartModalOpen = false;
    @track cart = [];

    newItemName = '';

    selectedSearchItem = '';
    selectedType = '';
    selectedFamily = '';

    wiredItemsResult;

    @wire(getAccountData, {accountId: '$recordId'})
    account;

    @wire(isUserManager)
    wiredManager({data}) {
        if (data)
            this.isManager = data;
    }

    @wire(getItems, {
        family: '$selectedFamily',
        type: '$selectedType',
        searchItem: '$selectedSearchItem'
    })
    wiredItems(data) {
        this.wiredItemsResult = data;
        if (data.data) {
            this.items = data.data;
        } else if (data.error) {
            console.error('Error fetching items:', data.error);
        }
    }

    get accName() {
        return this.account.data?.Name || 'N/A';
    }

    get accNumber() {
        return this.account.data?.AccountNumber || 'No Number';
    }

    get accIndustry() {
        return this.account.data?.Industry || 'No Industry';
    }

    typeOptions = ['Type 1', 'Type 2', 'Type 3']; //mocks

    familyOptions = ['Family 1', 'Family 2']; //mocks
    handleSearchChange(event) {
        this.selectedSearchItem = event.target.value;
    }

    handleCreateItem() {
        this.isCreateModalOpen = true;
    }

    closeCreateModal() {
        this.isCreateModalOpen = false;
    }

    handleNameChange(event) {
        this.newItemName = event.target.value;
    }

    async handleBeforeSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;

        if (this.newItemName) {
            try {
                const imageUrl = await getUnsplashImageUrl({ itemName: this.newItemName });
                fields.Image__c = imageUrl;
            } catch (error) {
                console.error('Unsplash error:', error);
            }
        }
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    handleCreateSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Item created successfully with Unsplash image!',
                variant: 'success'
            })
        );
        this.isCreateModalOpen = false;
        return refreshApex(this.wiredItemsResult);
    }

    addToCart(event) {
        const itemId = event.target.dataset.id;
        const item = this.items.find(i => i.Id === itemId);

        this.cart = [...this.cart, { ...item, Quantity: 1 }];

        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: item.Name + ' added to cart',
            variant: 'success'
        }));
    }

    get itemsCount() {
        return this.items.length;
    }

    toggleCart() {
        this.isCartModalOpen = !this.isCartModalOpen;
    }

    handleDetails(event) {
        const itemId = event.target.dataset.id;
        this.selectedItem = this.items.find(item => item.Id === itemId);
        this.isDetailsModalOpen = true;
    }

    closeDetailsModal() {
        this.isDetailsModalOpen = false;
    }
}