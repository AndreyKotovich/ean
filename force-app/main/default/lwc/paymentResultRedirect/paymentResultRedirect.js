import {LightningElement, track} from 'lwc';
import getCommunityHomeUrlAuraEnabled from '@salesforce/apex/PaymentHttpRequest.getCommunityHomeUrlAuraEnabled';
import {NavigationMixin} from "lightning/navigation";


export default class PaymentResultRedirect extends NavigationMixin(LightningElement) {
    @track isSpinner = true;
    @track showErrorMessage = false;
    @track errorMessage = '';

    connectedCallback() {
        //console.log('window.location', window.location);
        let urlParams = new URL(window.location);
        let payPalResponse = urlParams.searchParams.get("eppresponse");
        let io = urlParams.searchParams.get("oi");
        let ri = urlParams.searchParams.get("ri");

        getCommunityHomeUrlAuraEnabled()
            .then(result =>{
                if(payPalResponse != null && io != null && ri != null){
                    window.location.href = result + '/s/payment-result' + '?oi='+io+'&ri='+ri;
                } else {
                    window.location.href = result + '/s/';
                }
            })
            .catch(error => {
                console.log(error.message);
                this.isSpinner = false;
                this.errorMessage = 'Something went wrong, contact your system administrator.';
                this.showErrorMessage = true;
            });
    }
}