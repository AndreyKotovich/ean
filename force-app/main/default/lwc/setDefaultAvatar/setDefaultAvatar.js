import {LightningElement, track} from 'lwc';
import assignDefaultAvatar from '@salesforce/apex/setEANDefaultAvatar.assignDefaultAvatar'


export default class SetDefaultAvatar extends LightningElement {
    @track spinner = true;
    connectedCallback() {
        assignDefaultAvatar()
            .then(result=>{
                this.spinner = false;
                if(result){
                    location.reload();
                }
            })
            .catch(error=>{
                console.log(error);
                this.spinner = false;
            })
    }

}