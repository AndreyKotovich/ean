import {LightningElement, track} from 'lwc';
import getProduct2s from '@salesforce/apex/JournalBuyController.getProduct2s';
import {NavigationMixin} from "lightning/navigation";
import generateOrder from '@salesforce/apex/OrderUtils.generateOrder'
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getContact from '@salesforce/apex/JournalBuyController.getContact'

export default class JournalBuy extends NavigationMixin(LightningElement) {
    @track isShowProducts = false;
    @track products = [];
    @track productOptions = [];
    selectedProducts = [];
    @track isShowErrorScreen = false;
    contact = {};
    connectedCallback() {
        getProduct2s()
            .then(product2s => {
                for(let product of product2s){
                    if(product.hasOwnProperty('Description')){
                        if(product['Description'].includes('address above')){
                            let res = product['Description'].replace('address above','address provided in your MyEAN contact information');
                            product['Description'] = res;
                        }
                    }
                }
                this.products = [...product2s];
                this.setProductsToPage();
            })
            .catch(error => {
                console.log('getProduct2s:: ' + JSON.stringify(error));
            })
        getContact()
            .then(contact=>{
                this.contact = Object.assign({}, contact);
            })
            .catch(error=>{
                this.dispatchToast('Error', error.body.message, 'error');
                this.template.querySelector('.buy-button').disabled = true;
            })
    }
    setProductsToPage() {
        let productOptions = [];
        let line = 0;
        this.products.forEach(item => {
            if (item.hasOwnProperty('PricebookEntries')) {
                item['PricebookEntries'].forEach(PBEItem => {
                    if (PBEItem['Pricebook2']['Name'] === 'Membership Application') {
                        productOptions.push({
                            label: item['Name'],
                            value: item['Id'],
                            price: PBEItem['UnitPrice'],
                            line: 'checkbox-product ' + line,
                            description: item['Description']
                        });
                    }
                });
            }
            line++;
        });
        if (productOptions.length !== 0) {
            this.productOptions = [...productOptions];
            this.isShowProducts = true;
        } else {
            this.isShowErrorScreen = true;
        }
    }
    catchSelectedProducts() {
        let selectedProducts = [];
        var checkedValues = this.template.querySelectorAll('.checkbox-product:checked');
        checkedValues.forEach(item => {
            if (item.checked) {
                selectedProducts.push(item.value);
            }
        });
        this.selectedProducts = [...selectedProducts];
    }
    handleBuy() {
        if(this.selectedProducts.length!==0){
            generateOrder({
                ContactId: this.contact['Id'],
                orderItemsObject: this.generateOrderItems(),
                purchaseType: 'New'
            })
                .then(orderId => {
                    this.orderId = orderId;
                    this.navigateToPaymentPage(this.orderId);
                })
                .catch(error => {
                    console.log('generateOrder:: ' + JSON.stringify(error));
                });
        }else{
            this.dispatchToast('Error', 'Choose Journal(s)', 'error');
        }

    }
    generateOrderItems() {
        let listOrderItems = [];
        this.productOptions.forEach(option => {
            this.selectedProducts.forEach(selected => {
                if (option['value'] === selected) {
                    listOrderItems.push({'Product__c': selected, 'Amount__c': option['price'], 'Quantity__c': 1});
                }
            })
        });
        return listOrderItems;
    }
    navigateToPaymentPage(orderId) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'payment-component'
            },
            state: {
                orderId: orderId
            }
        });
    }
    dispatchToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }
}