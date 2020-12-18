import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getOrderInfo from "@salesforce/apex/OrderHelper.getOrderInfo";
import getCancellationSettings from "@salesforce/apex/OrderHelper.getCancellationSettings";
import cancelOrder from "@salesforce/apex/OrderHelper.cancelOrder";

export default class CancelOrder extends LightningElement {
    
    @track _recordId;
    @api get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.invokeCallout();
    }
    @track isSpinner = false;
    @track infoOrder;
    @track orderItem;

    @track displayContactColumn = false;

    invokeCallout() {
        this.infoOrder = {};
        this.orderItem = [];
        this.isSpinner = true;
        getCancellationSettings({ Id: this._recordId})
            .then(res => {
                this.isSpinner = false;
                console.log('getOrderInfo res', res);
                if (res.orderList.length > 0) {
                    this.infoOrder = res.orderList[0];
                    if (this.infoOrder.Status__c === 'Paid' && this.infoOrder.Paid_Amount__c === 0) {
                        this.dispatchToast('Error', 'Order returned in full.', 'Error');
                        this.dispatchEvent(new CustomEvent('closeQuickAction', {}));
                    }
                    this.orderItem = res.orderList[0].Order_Items__r;
                    this.orderItem.forEach(e => {
                        e.Refund_Amount__c = e.Refund_Amount__c || 0;
                        e.maxRef = e.Total_amount__c - e.Refund_Amount__c;
                    });
                    this.displayContactColumn = res.displayContactColumn;
                }
            })
            .catch(error => {
                this.isSpinner = false;
                console.log(error);
                this.dispatchToast('Error', 'Something went wrong.', 'Error');
                this.dispatchEvent(new CustomEvent('closeQuickAction', {}));
            });
    }

    refund() {
        this.isSpinner = true;
        let refundAmount = 0;
        let oIOrig = {};
        this.orderItem.forEach(e => {
            e.sobjectType = "Order_Item__c";
            e.Refund_Amount__c += e.maxRef;
            refundAmount += e.maxRef;
            if (+e.maxRef !== 0) {
                oIOrig[`${e.Id}`] = +e.maxRef;
            }
        });

        if (refundAmount == 0) {
            this.dispatchToast('Error', 'Invalid refund value', 'Error');
        }

        let generalData = {
            id : this.infoOrder.Id,
            refundAmount : refundAmount,
            oI: this.orderItem,
            oIOrig: oIOrig
        };

        cancelOrder({ generalData : generalData})
            .then(res => {
                this.isSpinner = false;
                this.dispatchToast(res.status, res.status === 'Success' ? 'Refund Successful' : res.message , res.status);
                if (res.status === 'Success') {
                    this.dispatchEvent(new CustomEvent('closeQuickAction', {}));
                }                
            })
            .catch(error => {
                this.isSpinner = false;
                this.dispatchToast('Error', 'Something went wrong.', 'Error');
                console.log(error);
            });
    }

    handleFieldChange(e) {
        let curOI = this.orderItem.find(el => el.Id === e.currentTarget.dataset.id);
        if (((curOI.Total_amount__c - curOI.Refund_Amount__c) < +e.target.value) || +e.target.value < 0) {
            this.dispatchToast('Error', 'Invalid refund value', 'Error');
            curOI[`${e.currentTarget.dataset.field}`] = 0;
            return;
        }

        curOI[`${e.currentTarget.dataset.field}`] = +e.target.value;
    }

    dispatchToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

}