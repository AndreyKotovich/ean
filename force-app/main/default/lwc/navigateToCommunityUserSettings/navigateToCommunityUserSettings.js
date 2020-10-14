import {LightningElement} from 'lwc';
import Id from '@salesforce/user/Id';
import {NavigationMixin} from "lightning/navigation";


export default class NavigateToCommunityUserSettings extends NavigationMixin(LightningElement) {

    connectedCallback() {
        let url = '/settings/'+Id;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }
}