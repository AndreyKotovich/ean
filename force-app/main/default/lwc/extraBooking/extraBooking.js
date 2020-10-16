import {LightningElement, track, api} from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Utils } from "c/utils";
import getExtraSessions from "@salesforce/apex/EventRegistrationController.getExtraSessions";

export default class ExtraBooking extends LightningElement {
    @api eanEvent = {};
    @api userInfo = {};
    @api registrationType = "";

    @track hideNextButton = false;
    @track hidePreviousButton = false;
    @track isSpinner = true;
    @track sessionsCheckboxGroup = [];

    eventExtraSessions = []; //all extra sessions for this event
    availableExtraSession = []; //sessions which are available for the participant
    isEarlyBird = false;

    connectedCallback() {
        if (this.registrationType !== "solo") return this.handleNextClick();

        this.isEarlyBird = this.eanEvent.Early_Bird_Deadline__c ? Utils.deadlineCheck(this.eanEvent.Early_Bird_Deadline__c) : false;

        let promise1 = getExtraSessions({eventId: this.eanEvent.Id});
        // let promise2 = getSessionsTickets({eventId: this.event.Id});

        Promise.all([promise1])
            .then(results =>{
                console.log(JSON.stringify(results));
                this.eventExtraSessions = results[0];

                if(Object.keys(results[0]).length === 0 && results[0].constructor === Object){
                    this.handleNextClick();
                } else {
                    this.parseSessionsAndPrice();
                }
                this.isSpinner = false;
            })
            .catch(error => {
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

    parseSessionsAndPrice(){

        for(let session of this.eventExtraSessions){

            if(!session.Event_Tickets__r) continue;

            for (let ticket of session.Event_Tickets__r) {

                if(session.Id !== ticket.Session__c) continue;

                const { Available_for_Countries__c, Available_for_Memberships__c } = ticket.Ticket__r;

                if (!Available_for_Countries__c || !Available_for_Countries__c.includes(this.userInfo.countyRegion))
                    continue;

                if (!Available_for_Memberships__c) {
                    this.availableExtraSession.push(ticket);
                } else {

                    for (let membership of this.userInfo.memberships) {
                        if (Available_for_Memberships__c.includes(membership.Membership__r.API__c)) {
                            this.availableExtraSession.push(ticket);
                            break;
                        }
                    }

                }
            }
        }

        this.generateCheckboxGroup()
    }

    generateCheckboxGroup(){
        let sessionsCheckboxGroup = [];

        console.log(JSON.stringify(this.availableExtraSession));

        for(let [i, ticket] of this.availableExtraSession.entries()){

            let price = this.isEarlyBird ? ticket.Early_bird_price__c : ticket.Price__c;
            if(price === undefined) continue;

            sessionsCheckboxGroup.push({
                elementId: 'extra-session-'+i,
                value: ticket.Id,
                label: ticket.Session__r.Name,
                description: ticket.Session__r.Description__c,
                price: price
            });
        }

        this.sessionsCheckboxGroup = [...sessionsCheckboxGroup];
    }
}