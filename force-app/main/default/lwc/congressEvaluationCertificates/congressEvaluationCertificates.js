import {LightningElement, api, track} from 'lwc';
import getCertificatesLinks from '@salesforce/apex/CongressEvaluationCertificatesCtrl.getCertificatesLinks'


export default class CongressEvaluationCertificates extends LightningElement {
    @api recordId;
    @track certificateLinks = [];
    @track spinner = true;
    @track isError = false;
    @track errorMessage = '';
    connectedCallback() {
        getCertificatesLinks()
            .then(result => {
                this.spinner = false;

                //Check result on errors
                for( let congress of result ) {
                    congress.isError = false;
                    if(congress.hasOwnProperty('isParticipantFound')){
                        congress.isError = !congress.isParticipantFound;
                    }
                    if( !congress.isError ){
                        if(congress.hasOwnProperty('congressCertificateLinks')){
                            congress.isError = !congress.congressCertificateLinks.length > 0;
                        } else {
                            congress.isError = true;
                        }
                        if(congress.isError){
                            congress.errorMessage = 'Certificates are not found';
                        }
                    } else {
                        congress.errorMessage = 'Participation is not found';
                    }
                }

                this.certificateLinks = [...JSON.parse(JSON.stringify(result))];
            })
            .catch(error => {
                this.isError = true;
                this.errorMessage = 'Something went wrong';

                if(error.hasOwnProperty('body')) {
                    if (!error.hasOwnProperty('isUserDefinedException')) {
                        if (error.body.hasOwnProperty('message')) this.errorMessage = error.body.message;
                    }
                }

                console.log('error_getCertificatesLinks:: '+JSON.stringify(error));
                this.spinner = false;
            })
    }
}