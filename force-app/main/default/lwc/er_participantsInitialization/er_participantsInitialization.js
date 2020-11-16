import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {Utils} from "c/utils";
// APEX
import getContactInfo from "@salesforce/apex/EventRegistrationController.getContactInfo";
import getCountries from "@salesforce/apex/membershipApplicationController.getCountries";
import getContactMemberships from "@salesforce/apex/Utils.getContactMemberships";

export default class ErParticipantsInitialization extends LightningElement {
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

        this.isSpinner = false;
    }

    handleSelectEmail(event){
        let recordDetails = JSON.parse(event.detail.recorddetails);
        let index = event.target.dataset.index;
        this._participantsInitialization.initializedParticipants[index].contact.Id =  recordDetails.id ? recordDetails.id : '';
        this._participantsInitialization.initializedParticipants[index].contact.Email =  recordDetails.enteredText ? recordDetails.enteredText : '';

        if(!recordDetails.id){
            this._participantsInitialization.initializedParticipants[index].showPill = false;
            this._participantsInitialization.initializedParticipants[index].foundContact = false;
            this._participantsInitialization.initializedParticipants[index].selectedTicket = '';
            this._participantsInitialization.initializedParticipants[index].participantRole = '';
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
            Promise.all([
                getContactInfo({contactId: this._participantsInitialization.initializedParticipants[index].contact.Id}),
                getContactMemberships({contactId: this._participantsInitialization.initializedParticipants[index].contact.Id})
            ])
                .then(results => {
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
                })
                .catch(error => {
                    console.log('error', error);
                })
        }
    }

    onSelectTicket(event){
        let index = event.target.dataset.index;
        this._participantsInitialization.initializedParticipants[index].selectedTicket = event.detail.selectedTicket;
        this._participantsInitialization.initializedParticipants[index].ticketId = event.detail.ticketId;
        this._participantsInitialization.initializedParticipants[index].priceTicket = event.detail.priceTicket;
        this._participantsInitialization.initializedParticipants[index].ticketName = event.detail.ticketName;
        this._participantsInitialization.initializedParticipants[index].pillLabel = event.detail.ticketName + ' - ' + event.detail.priceTicket + ' €';
        this._participantsInitialization.initializedParticipants[index].showPill = true;
        this._participantsInitialization.initializedParticipants[index].foundContact = false; //TODO remane foundContact
        this._participantsInitialization.initializedParticipants[index].participantRole = event.detail.participantRole;
    }

    get usedEmailsString(){
        return JSON.stringify(this.usedEmails);
    }

    handleRemoveTicket(event){
        let index = event.target.dataset.index;
        this._participantsInitialization.initializedParticipants[index].showPill = false;
        this._participantsInitialization.initializedParticipants[index].foundContact = true; //TODO remane foundContact
        this._participantsInitialization.initializedParticipants[index].selectedTicket = '';
        this._participantsInitialization.initializedParticipants[index].ticketId = '';
        this._participantsInitialization.initializedParticipants[index].priceTicket = '';
        this._participantsInitialization.initializedParticipants[index].ticketName = '';
        this._participantsInitialization.initializedParticipants[index].pillLabel = '';
        this._participantsInitialization.initializedParticipants[index].participantRole = '';

    }

    handleSelectTicketError(event){
        this.dispatchToast('Error', 'Something went wrong, please, contact your system administrator.', 'error');
    }

    handleTicketsNotFound(event){
        this.dispatchToast('Error', 'Tickets not found for the contact', 'error');
        let index = event.target.dataset.index;
        this._participantsInitialization.initializedParticipants[index].showPill = false;
        this._participantsInitialization.initializedParticipants[index].foundContact = false;
    }

    handlePreviousClick() {
        const selectEvent = new CustomEvent("previous", {
            detail: {}
        });
        this.dispatchEvent(selectEvent);
    }

    handleNextClick() {
        if(this.nextClickValidation()){
            const selectEvent = new CustomEvent("continue", {
                detail: {
                    participantsInitialization: this._participantsInitialization
                }
            });
            this.dispatchEvent(selectEvent);
        }
    }

    nextClickValidation(){
        let result = true;
        let participantsWithTickets = [];
        let message = '';

        for(let initializedParticipant of this._participantsInitialization.initializedParticipants){

            if(initializedParticipant.contact.Email){
                if(!Utils.emailValidationRegex(initializedParticipant.contact.Email)){
                    result = false;
                    message = 'Check your input, only emails available';
                    break;
                }
            } else {
                result = false;
                message = 'Complete all fields';
                break;
            }

            if(!!initializedParticipant.selectedTicket && !!initializedParticipant.ticketId){
                participantsWithTickets.push(initializedParticipant);
            }

        }

        if(!result){
            this.dispatchToast('Error', message, 'error');
        }

        //cut unfilled participants
        if(result && participantsWithTickets.length !== this._participantsInitialization.initializedParticipants.length){

            if(confirm('Participants without tickets are found, they will be removed')){
                result = true;
                this._participantsInitialization.initializedParticipants = [...participantsWithTickets];
                this._participantsInitialization.participantsAmount = participantsWithTickets.length;
            } else {
                result = false;
            }

        }

        return result;
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