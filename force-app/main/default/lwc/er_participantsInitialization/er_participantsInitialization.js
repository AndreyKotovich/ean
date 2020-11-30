import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {Utils} from "c/utils";
// APEX
import getContactInfo from "@salesforce/apex/EventRegistrationController.getContactInfo";
import getCountries from "@salesforce/apex/membershipApplicationController.getCountries";
import getContactMemberships from "@salesforce/apex/EventRegistrationController.getContactMemberships";
import getNotAvailableEventRegistrationEmails from "@salesforce/apex/EventRegistrationController.getNotAvailableEventRegistrationEmails";

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
    @track usedEmails = []; //emails which are selected during work of component
    registeredEmails = []; //emails that are already registered in the Salesforce
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
                arr.push({contact:{Id: '', Email: ''}, error:{}});
            }

            this._participantsInitialization.initializedParticipants = this._participantsInitialization.initializedParticipants.concat(arr);

        } else if(this._participantsInitialization.participantsAmount < this._participantsInitialization.initializedParticipants.length){
            this._participantsInitialization.initializedParticipants = this._participantsInitialization.initializedParticipants.slice(0, this._participantsInitialization.participantsAmount);
        }

        let promises = [
            getCountries(),
            getNotAvailableEventRegistrationEmails({eventsIds: [this.eanEvent.Id]})
        ];

        Promise.all(promises)
            .then(results => {
                this.allCountriesAndRegions = [...results[0]];
                this.registeredEmails = [...results[1]];
                this.isSpinner = false;
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
    }

    handleSelectEmail(event){
        let recordDetails = JSON.parse(event.detail.recorddetails);
        console.log('recordDetails', JSON.stringify(recordDetails));
        let index = event.target.dataset.index;
        this._participantsInitialization.initializedParticipants[index].contact.Id =  recordDetails.id ? recordDetails.id : '';
        this._participantsInitialization.initializedParticipants[index].contact.Email =  recordDetails.enteredText ? recordDetails.enteredText : '';
        this._participantsInitialization.initializedParticipants[index].error = {};

        if(!recordDetails.id){
            this._participantsInitialization.initializedParticipants[index].showPill = false;
            this._participantsInitialization.initializedParticipants[index].foundContact = false;
            this._participantsInitialization.initializedParticipants[index].selectedTicket = '';
            this._participantsInitialization.initializedParticipants[index].participantRole = '';
            this._participantsInitialization.initializedParticipants[index].eventPersonaId = '';
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
        this._participantsInitialization.initializedParticipants[index].eventPersonaId = event.detail.eventPersonaId;
        this._participantsInitialization.initializedParticipants[index].isOnlineTicket = event.detail.isOnlineTicket;
    }

    get usedEmailsString(){
        let arr = this.registeredEmails.concat(this.usedEmails);
        return JSON.stringify(arr);
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
        this._participantsInitialization.initializedParticipants[index].eventPersonaId = '';
        this._participantsInitialization.initializedParticipants[index].isOnlineTicket = false;
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

            message = 'Check your inputs';

            if(initializedParticipant.contact.Email){
                if(!Utils.emailValidationRegex(initializedParticipant.contact.Email)){
                    result = false;
                    initializedParticipant.error = {hasError: true, message: 'Only email allowed here'};
                }

                if(this.registeredEmails.includes(initializedParticipant.contact.Email)){
                    initializedParticipant.error = {hasError: true, message: 'Participant is already registered'};
                    result = false;
                }

            } else {
                initializedParticipant.error = {hasError: true, message: 'Complete this field'};
                result = false;
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