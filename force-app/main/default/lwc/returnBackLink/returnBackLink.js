import { LightningElement, api } from 'lwc';

export default class ReturnBackLink extends LightningElement {
    @api 
    label;
    @api
    queryParameter;
    
    returnUrl;

    async connectedCallback() {
        if (document.location.search && document.location.search.length > 1) {
            let params = document.location.search.substr(1).split('&');
            let param = params.find(p => p.split('=')[0] == this.queryParameter);
            if (param) {
                this.returnUrl = decodeURIComponent(param.split('=')[1]);
            }
        }
    }
}