import {LightningElement, api, wire, track } from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {Utils} from "c/utils";
// import { getPicklistValues } from 'lightning/uiObjectInfoApi';
// import {getObjectInfo} from 'lightning/uiObjectInfoApi';


export default class ErSummarize extends LightningElement {



    data = [
        {name: 'Ticket Free contingent', quantity: 'x1', amount: '500 €'},
        {name: 'Ticket Free contingent2', quantity: 'x1', amount: '500 €'},
        {name: 'Ticket Free contingent3', quantity: 'x1', amount: '500 €'},
    ]

    // @api eanEvent = {};

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

    _selections = {};


    connectedCallback() {

        console.log(JSON.parse(JSON.stringify(this._selections)));

        if(this._selections.selectedTickets && this._selections.selectedTickets.length > 0){
            this.hasTickets = true;
            //generate table items
        }

        if(this._selections.selectedSessions && this._selections.selectedSessions.length > 0){
            this.hasSessions = true;
            //generate table items
        }

        this.isSpinner = false;
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

    get showVisaLetter(){
        if(!this._selections.selectedServices) return false;

    }

}