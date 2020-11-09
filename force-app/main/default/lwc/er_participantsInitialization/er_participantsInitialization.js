import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Utils } from "c/utils";

export default class ErParticipantsInitialization extends LightningElement {
    // obj = {
    //     isPartInit: true,
    //     initializedParticipants: [
    //         {
    //             contactId: '1231',
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
        console.log('this._participantsInitialization', JSON.stringify(value));
        this._participantsInitialization = Object.assign({}, value);
    }

    @track hideNextButton = false;
    @track hidePreviousButton = false;
    @track isSpinner = true;

    _participantsInitialization = {};

    connectedCallback() {
        this.isSpinner = false;
    }

    handleSelectEmail(event){
        console.log('here');
        console.log(JSON.stringify(event.detail));
        console.log(JSON.parse(JSON.stringify(event.detail)));
        console.log(event.detail);
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
}