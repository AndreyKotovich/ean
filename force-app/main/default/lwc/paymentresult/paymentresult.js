import {LightningElement, track} from 'lwc';
import getPaymentInfoByRequestId from '@salesforce/apex/PaymentHttpRequest.getPaymentInfoByRequestId';
import insertLog from '@salesforce/apex/PaymentHttpRequest.insertLog';
import determineSuccessScreen from '@salesforce/apex/OrderUtils.determineSuccessScreen';
export default class Paymentresult extends LightningElement {
    @track showErrorMessage = false;
    @track errorMessage = 'Error';
    payPalResponse = '';
    recallCounter = 0;
    connectedCallback() {
        let urlParams = new URL(window.location);
        this.payPalResponse = urlParams.searchParams.get("eppresponse");
        if(urlParams.searchParams.get("eppresponse") != null){
            let updatedUrl = urlParams.origin + urlParams.pathname + '?oi='+urlParams.searchParams.get("oi")+'&ri='+urlParams.searchParams.get("ri");
            window.history.pushState({}, "", updatedUrl);
        }
        this.parseUrl();
    }
    parseUrl(){
        var urlParams = new URL(window.location);
        getPaymentInfoByRequestId({requestId:urlParams.searchParams.get("ri"), orderId:urlParams.searchParams.get("oi")})
            .then(result=>{
                if(result==='Success'){
                    this.template.querySelector('.spinner').style.display = 'none';
                    this.showAndDetermineSuccessScreen(urlParams.searchParams.get("oi"));
                } else {
                    //call getPaymentInfoByRequestId() once again if on second time error, create log with url response.
                    if(this.recallCounter === 0){
                        this.recallCounter++;
                        this.parseUrl();
                    }

                    if(result==='Error'){
                        this.errorMessage = 'Your payment has failed.';
                        this.template.querySelector('.spinner').style.display = 'none';
                        this.showErrorMessage = true;
                    } else {
                        this.errorMessage = result;
                        this.template.querySelector('.spinner').style.display = 'none';
                        this.showErrorMessage = true;
                    }

                }
            })
            .catch(error=>{
                let log = {
                    'Process_Name__c':'REST: PayPal response from url parseUrl() catch',
                    'Order__c':urlParams.searchParams.get("oi"),
                    'Type__c':'REST',
                    'Message__c':JSON.stringify(error),
                    'Status__c' : 'Error',
                    'End_Time__c' : new Date()
                };
                insertLog({log: JSON.stringify(log)})
                    .catch(e=>{console.log('insertLog_ERROR: '+JSON.stringify(e));})
                    .finally(()=>{
                        console.log('error '+JSON.stringify(error.body.message));
                        this.errorMessage = error.body.message;
                        this.template.querySelector('.spinner').style.display = 'none';
                        this.showErrorMessage = true;
                    });
            })
    }
    showAndDetermineSuccessScreen(orderId){
        determineSuccessScreen({orderId:orderId})
            .then(result=>{
                let title, message;
                if(result === 'ORDER'){
                    title = 'Your payment was received, thank you!';
                    message = '';
                    this.showSuccessScreen(title, message);
                } else if(result === 'ORDER_WITH_APP_FORM'){
                    title = 'Thank you for your payment. Your application has been submitted for review.';
                    message = 'If you do not hear back from us within 10 working days, please contact us at <a href="mailto:membership@ean.org">membership@ean.org</a>.';
                    this.showSuccessScreen(title, message);
                }
            })
    }
    showSuccessScreen(title, message){
        let successPaymentScreen = this.template.querySelector('.success-screen');
        let body =
            `<div class="slds-grid slds-grid_vertical slds-text-align_center slds-m-around--small">
                <div class="slds-col">
                    <div class="slds-text-heading_large slds-text-color_success">${title}</div>
                </div>
                <div class="slds-col">
                    <div class="slds-text-heading_small slds-m-top--medium">${message}</div>
                </div>
            </div>`;
        successPaymentScreen.insertAdjacentHTML('afterbegin', body);
        successPaymentScreen.removeAttribute('hidden');
        this.template.querySelector('.spinner').style.display = 'none';
    }
}