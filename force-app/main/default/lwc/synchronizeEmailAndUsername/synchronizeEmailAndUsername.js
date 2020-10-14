import {LightningElement} from 'lwc';
import synchronize from '@salesforce/apex/SynchronizeEmailAndUsername.synchronize'
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class SynchronizeEmailAndUsername extends LightningElement {
    handleUpdate(){
        synchronize()
            .then(()=>{
                this.dispatchToast('Success', 'Username successfully updated. Refresh the page to see updated information.', 'success');
            })
            .catch(error => {
                this.dispatchToast('Error', error.body.message, 'error');
                console.log(error);
            })
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