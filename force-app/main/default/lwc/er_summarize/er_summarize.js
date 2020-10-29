import {LightningElement, api, wire, track } from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {Utils} from "c/utils";
import getPicklistValues from "@salesforce/apex/EventRegistrationController.getPicklistValues";
import getEventTicketsLabels from "@salesforce/apex/EventRegistrationController.getEventTicketsLabels";


export default class ErSummarize extends LightningElement {

    @api
    get selections(){
        return this._selections;
    }
    set selections(value){
      this._selections = Object.assign({}, value);
    }

    @track hasTickets = false;
    @track hasSessions = false;
    @track hideNextButton = false;
    @track hidePreviousButton = false;
    @track isSpinner = true;
    @track ticketsTable = [];
    @track sessionsTable = [];
    @track totalAmount = 0;

    _selections = {};
    badgePicklistValues = [];

    connectedCallback() {

        let eventTicketsIds = [];

        if(this._selections.selectedTickets && this._selections.selectedTickets.length > 0){
            this.hasTickets = true;

            for(let ticket of this._selections.selectedTickets){
                eventTicketsIds.push(ticket.ticketId);
            }
        }

        if(this._selections.selectedSessions && this._selections.selectedSessions.length > 0){
            this.hasSessions = true;

            for(let ticket of this._selections.selectedSessions){
                eventTicketsIds.push(ticket.id);
            }
        }

        let promises = [
            getPicklistValues({objectName: 'Participant__c', fieldName: 'Badge_Retrieval__c'}),
            getEventTicketsLabels({eventTicketsIds: eventTicketsIds})
        ];

        Promise.all(promises)
            .then(results => {
                this.badgePicklistValues = [...results[0]];

                if(results[1] <= 0){
                    this.hasTickets = false;
                    this.hasSessions = false;
                }

                if(this.hasTickets){

                    for(let ticket of this._selections.selectedTickets){
                        if(!results[1][ticket.ticketId]) continue;

                        let amount = ticket.amount * ticket.quantity;

                        this.ticketsTable.push(
                            {
                                name: results[1][ticket.ticketId],
                                quantity: ticket.quantity,
                                amount: amount
                            },
                        );

                        this.totalAmount += amount;
                    }

                }

                if(this.hasSessions){

                    for(let session of this._selections.selectedSessions){
                        if(!results[1][session.id]) continue;

                        this.sessionsTable.push(
                            {
                                name: results[1][session.id],
                                quantity: 1,
                                amount: session.price
                            },
                        );

                        this.totalAmount += session.price;
                    }

                }

                console.log('ticketsTable', this.ticketsTable);
                console.log('sessionsTable', this.sessionsTable);

                this.isSpinner = false;
            })
            .catch(error=>{
                this.isSpinner = false;
                let message = '';
                if(error.body){
                    if(error.body.message){
                        message = error.body.message;
                    }
                }
                this.throwError({message: message});
            })


    }

    handlePreviousClick() {
        const selectEvent = new CustomEvent("previous", {
            detail: {}
        });
        this.dispatchEvent(selectEvent);
    }

    handleNextClick() {
        const selectEvent = new CustomEvent("continue", {
            detail: {}
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

    get showBadgeRetrieval(){
        if(!this._selections.selectedServices) return false;
        return !!this._selections.selectedServices.badgeRetrieval;
    }

    get badgeRetrievalLabel(){
        let result = '';

        if(this.showBadgeRetrieval){
            let picklistValue = this.badgePicklistValues.find(obj=>obj.value === this._selections.selectedServices.badgeRetrieval);

            if(!!picklistValue){
                result = picklistValue.label;
            }

        }

        return result;
    }

    get showVisaLetter(){
        if(!this._selections.selectedServices || !this._selections.selectedServices.visaLetter) return false;
         return this._selections.selectedServices.visaLetter;
    }

}