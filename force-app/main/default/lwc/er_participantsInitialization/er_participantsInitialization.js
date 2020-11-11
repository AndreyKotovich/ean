import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
// APEX
import getContactInfo from "@salesforce/apex/EventRegistrationController.getContactInfo";
import getCountries from "@salesforce/apex/membershipApplicationController.getCountries";
import getContactMemberships from "@salesforce/apex/Utils.getContactMemberships";



//TODO validation every lookup must be filled
//TODO validation every lookup must be selected with a ticket
//TODO change group to solo, additional screen appears
//TODO if empty input hide the ticket cmp
//TODO prev cmp  styles
export default class ErParticipantsInitialization extends LightningElement {
    // obj = {
    //     isPartInit: true,
    //     initializedParticipants: [
    //         {
    //             foundContact: false,
    //             contact: {
    //                 // Contact
    //             },
    //             ticket: {
    //                 // Ticket__c
    //             },
    //             eventTicket: {
    //                 // Event_Ticket__c
    //             },
    //             price: '100500'
    //         }
    //     ]
    //
    // }

    @api
    get participantsInitialization(){
        return this._participantsInitialization;
    }
    set participantsInitialization(value){
        this._participantsInitialization = JSON.parse(JSON.stringify(value));
    }
    @api eanEvent = {};

    @track hideNextButton = false;
    @track hidePreviousButton = false;
    @track isSpinner = true;

    @track _participantsInitialization = {};
    @track usedEmails = [];
    allCountriesAndRegions = [];

    selectTicketSize = {
        size: 12,
        largeDeviceSize: 12,
        mediumDeviceSize: 12,
        smallDeviceSize: 12
    }

    selectTicketMarkupSettings = {
        hidePreviousButton: true,
        nextButtonLabel: 'Select',
        hideHeader: true
    }

    connectedCallback() {

        console.log('participantsAmount '+this._participantsInitialization.participantsAmount);
        console.log('length '+this._participantsInitialization.initializedParticipants.length);
        console.log('array diff', this._participantsInitialization.participantsAmount < this._participantsInitialization.initializedParticipants.length);


        if(this._participantsInitialization.participantsAmount > this._participantsInitialization.initializedParticipants.length){
            let arrayDifference = this._participantsInitialization.participantsAmount - this._participantsInitialization.initializedParticipants.length;
            let arr = [];

            for(let i = 0; i < arrayDifference; i++){
                arr.push({contact:{Id: '', Email: ''}});
            }

            this._participantsInitialization.initializedParticipants = this._participantsInitialization.initializedParticipants.concat(arr);

        } else if(this._participantsInitialization.participantsAmount < this._participantsInitialization.initializedParticipants.length){
            this._participantsInitialization.initializedParticipants = this._participantsInitialization.initializedParticipants.slice(0, this._participantsInitialization.participantsAmount);
        }

        getCountries()
            .then(result => {
                this.allCountriesAndRegions = [...result];
            })
            .catch(error => {
                this.isSpinner = false;
                let message = "";
                if (error.body) {
                    if (error.body.message) {
                        message = error.body.message;
                    }
                }
                this.throwError({message: message});
            })

        console.log('this._participantsInitialization', JSON.stringify(this._participantsInitialization));

        this.isSpinner = false;
    }

    handleSelectEmail(event){
        // let delay = 1000;
        // window.clearTimeout(this.delayTimeout);
        // this.delayTimeout = setTimeout(() => {

            let recordDetails = JSON.parse(event.detail.recorddetails);
            console.log('recordDetails', recordDetails);
            let index = event.target.dataset.index;
            this._participantsInitialization.initializedParticipants[index].contact.Id =  recordDetails.id ? recordDetails.id : '';
            this._participantsInitialization.initializedParticipants[index].contact.Email =  recordDetails.enteredText ? recordDetails.enteredText : '';

            if(!recordDetails.id){
                this._participantsInitialization.initializedParticipants[index].showPill = false;
                this._participantsInitialization.initializedParticipants[index].foundContact = false;
                this._participantsInitialization.initializedParticipants[index].selectedTicket = '';
                this._participantsInitialization.initializedParticipants[index].ticketId = '';
                this._participantsInitialization.initializedParticipants[index].priceTicket = '';
                this._participantsInitialization.initializedParticipants[index].ticketName = '';
                this._participantsInitialization.initializedParticipants[index].pillLabel = '';
            }

            let usedEmails = [];

            for(let participant of this._participantsInitialization.initializedParticipants){
                if(participant.contact && participant.contact.Email && !!participant.contact.Email) usedEmails.push(participant.contact.Email);
            }

            this.usedEmails = usedEmails;

            if(!!this._participantsInitialization.initializedParticipants[index].contact.Id){
                //do callout
                Promise.all([
                    getContactInfo({contactId: this._participantsInitialization.initializedParticipants[index].contact.Id}),
                    getContactMemberships({contactId: this._participantsInitialization.initializedParticipants[index].contact.Id})
                ])
                    .then(results => {
                        console.log('results', JSON.stringify(results));
                        if(results[0].contact && results[0].contact.Id){
                            this._participantsInitialization.initializedParticipants[index].foundContact = true;
                            this._participantsInitialization.initializedParticipants[index].userInfo = results[0];
                        }
                        if(results[1] && this._participantsInitialization.initializedParticipants[index].foundContact){
                            this._participantsInitialization.initializedParticipants[index].userInfo.memberships = results[1];
                        }

                        if(this._participantsInitialization.initializedParticipants[index].foundContact){

                            for (let country of this.allCountriesAndRegions) {
                                if (country.Country__c === this._participantsInitialization.initializedParticipants[index].userInfo.contact.Residency__c) {
                                    this._participantsInitialization.initializedParticipants[index].userInfo.countyRegion = country.Region__c;
                                    break;
                                }
                            }

                        }

                        console.log('contact ', this._participantsInitialization.initializedParticipants[index]);

                    })
                    .catch(error => {
                        console.log('error', error);
                    })
            }

            //IF CONTACT WASN'T FOUND LOGIC
            //here
            //here

        // }, delay);
    }

    onSelectTicket(event){
        console.log(JSON.stringify(event.detail));
        let index = event.target.dataset.index;
        this._participantsInitialization.initializedParticipants[index].selectedTicket = event.detail.selectedTicket;
        this._participantsInitialization.initializedParticipants[index].ticketId = event.detail.ticketId;
        this._participantsInitialization.initializedParticipants[index].priceTicket = event.detail.priceTicket;
        this._participantsInitialization.initializedParticipants[index].ticketName = event.detail.ticketName;
        this._participantsInitialization.initializedParticipants[index].pillLabel = event.detail.ticketName + ' - ' + event.detail.priceTicket + ' €';
        this._participantsInitialization.initializedParticipants[index].showPill = true;
        this._participantsInitialization.initializedParticipants[index].foundContact = false; //TODO remane foundContact
    }

    get usedEmailsString(){
        return JSON.stringify(this.usedEmails);
    }

    handleRemoveTicket(event){
        try{

            let index = event.target.dataset.index;
            console.log('handleRemoveTicket', index);
            console.log('this._participantsInitialization.initializedParticipants', JSON.stringify(this._participantsInitialization.initializedParticipants[index]));
            console.log(this._participantsInitialization.initializedParticipants[index]);

            // let temp = this._participantsInitialization.initializedParticipants[index];

            this._participantsInitialization.initializedParticipants[index].showPill = false;
            console.log('after showPill');
            this._participantsInitialization.initializedParticipants[index].foundContact = true; //TODO remane foundContact
            this._participantsInitialization.initializedParticipants[index].selectedTicket = '';
            this._participantsInitialization.initializedParticipants[index].ticketId = '';
            this._participantsInitialization.initializedParticipants[index].priceTicket = '';
            this._participantsInitialization.initializedParticipants[index].ticketName = '';
            this._participantsInitialization.initializedParticipants[index].pillLabel = '';

        } catch (e){
            console.log('err', JSON.stringify(e));
            console.log('err', JSON.stringify(e.message));
        }

    }

    handleSelectTicketError(event){
        this.dispatchToast('Error', 'Something went wrong, please, contact your system administrator.', 'error');
    }

    handleTicketsNotFound(event){
        this.dispatchToast('Error', 'Tickets not found for the contact', 'error');
        let index = event.target.dataset.index;
        this._participantsInitialization.initializedParticipants[index].showPill = false;
        this._participantsInitialization.initializedParticipants[index].foundContact = false;

        //TODO process not found
    }



    handlePreviousClick() {
        const selectEvent = new CustomEvent("previous", {
            detail: {}
        });
        this.dispatchEvent(selectEvent);
    }

    handleNextClick() {
        const selectEvent = new CustomEvent("continue", {
            detail: {
                participantsInitialization: this._participantsInitialization
            }
        });
        this.dispatchEvent(selectEvent);
    }

    throwError(error) {
        const selectEvent = new CustomEvent("error", {
            detail: error
        });
        this.dispatchEvent(selectEvent);
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