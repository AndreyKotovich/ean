import {LightningElement, track, api} from "lwc";
import getProduct2s from '@salesforce/apex/EanJournalsController.getProduct2s';

export default class EanJournals extends LightningElement {

    @track products = [];
    @track productOptions = [];
    @track isShowErrorScreen = false;
    @track isSpinner = true;
    @track errorMessage = 'Something went wrong, please, contact your system administrator.';

    @api autoPopulate = [];

    connectedCallback() {
        getProduct2s()
            .then(product2s => {
                for (let product of product2s) {
                    if (product.hasOwnProperty('Description')) {
                        if (product['Description'].includes('address above')) {
                            //TODO replace in mem. app.
                            let res = product['Description'].replace('address above', 'address provided in your MyEAN contact information');
                            product['Description'] = res;
                        }
                    }
                }
                this.products = [...product2s];
                this.setProductsToPage();
            })
            .catch(error => {
                console.log('getProduct2s:: ' + JSON.stringify(error));
                this.isShowErrorScreen = true;
            })
            .finally(() => {
                this.isSpinner = false;
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
                            description: item['Description'],
                            checked: false
                        });
                    }
                });
            }
            line++;
        });
        if (productOptions.length !== 0) {
            this.productOptions = [...productOptions];
        } else {
            this.errorMessage = 'Sorry, there are no Journal(s) for sale.';
            this.isShowErrorScreen = true;
        }
    }


    catchSelectedProducts(event) {
        console.log(event.target.value);
        console.log(event.target.checked);
        let option = this.productOptions.find( obj => obj.value === event.target.value);
        option.checked = event.target.checked;

        console.log(JSON.stringify(this.productOptions));

        // let selectedProducts = [];
        // let checkedValues = this.template.querySelectorAll('.checkbox-product:checked');
        //
        // for(let item of checkedValues) {
        //     if (!item.checked) continue;
        //     let option = this.productOptions.find( obj => obj.value === item.value);
        //     selectedProducts.push({
        //         productId: option.value,
        //         price: option.price,
        //         quantity: 1
        //     });
        // }

        // console.log('selectedProducts: '+JSON.stringify(selectedProducts));
        // const selectEvent = new CustomEvent("select", {
        //     detail: {
        //         selectedProducts: selectedProducts
        //     }
        // });
        //
        // this.dispatchEvent(selectEvent);
    }

}