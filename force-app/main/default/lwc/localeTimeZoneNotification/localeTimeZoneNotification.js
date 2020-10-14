import {LightningElement, track} from 'lwc';
import showModalCheck from '@salesforce/apex/LocaleTimeZoneNotificationController.showModalCheck'
import writeNotificationTime from '@salesforce/apex/LocaleTimeZoneNotificationController.writeNotificationTime'
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";


export default class LocaleTimeZoneNotification extends NavigationMixin(LightningElement) {
    @track modal = false;
    @track values = {};
    connectedCallback() {
        showModalCheck()
            .then(result=>{
                console.log(JSON.stringify(result));
                this.values = Object.assign({}, result);
                this.userId = result.hasOwnProperty('userId')?result['userId']:'';
                if(result['result']){
                    this.openModal();
                }
            })
            .catch(error=>{
                console.log('localeTimeZoneNotification component');
                console.log('showModalCheck__ERROR:: '+JSON.stringify(error));
            })
    }

    openModal() {
        this.modal = true
    }
    closeModal() {
        this.modal = false
    }
    navigateToMySettings() {
        this.writeNotificationDateTime()
            .then(()=>{
                let url = '/settings/';
                url+=this.values.hasOwnProperty('userId')?this.values['userId']:'';
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: url
                    }
                });
                this.closeModal();
            })
            .catch(()=>{
                this.closeModal();
            });
    }
    closeClick(){
        this.writeNotificationDateTime()
            .then(()=>{
                this.closeModal();
            })
            .catch(()=>{
                this.closeModal();
            })
    }

    writeNotificationDateTime(){
        return new Promise((resolve, reject) => {
            //write Locale_Time_Zone_Notification_Date__c to current user
            writeNotificationTime()
                .then(() => {
                    resolve();
                })
                .catch(error => {
                    console.log('localeTimeZoneNotification component');
                    console.log('writeNotificationTime__ERROR:: ' + JSON.stringify(error));
                    let message = 'Something went wrong';
                    if (error.hasOwnProperty('body')) {
                        if (!error.hasOwnProperty('isUserDefinedException')) {
                            if (error.body.hasOwnProperty('message')) message = error.body.message;
                        }
                    }
                    this.dispatchToast('Error', message, 'error');
                    reject();
                })
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