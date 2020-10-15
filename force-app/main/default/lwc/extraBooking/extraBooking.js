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

    daysAndSessions = {};
    activeSessions = []; //used to auto open all accordions

    connectedCallback() {
        let promise1 = getExtraSessions({eventId: this.event.Id});
        let promise2 = getSessionsTickets({eventId: this.event.Id});

        Promise.all([promise1])
            .then(results =>{
                this.isSpinner = false;
                this.daysAndSessions = results[0];

                if(Object.keys(results[0]).length === 0 && results[0].constructor === Object){
                    this.handleNextClick();
                } else {
                    let keys = Object.keys(results[0]);
                    this.activeSessions = [...keys];
                    this.compileAccordionArrays();
                }
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

    compileAccordionArrays(){
        let daysAndSessions = Object.assign({}, this.daysAndSessions);
        let accordionArray = [];
        let uniqueIteration = 0;
        let displayedMutualExclusionSetIds = new Set();

        for(let date in daysAndSessions){
            if(!daysAndSessions.date) continue;

            let accordion = {};
            let checkboxValues = [];
            let radioButtons = [];
            let mutualExclSessionsMap = {};

            for(let session of daysAndSessions[date]){
                let isDisabled = session['Registrations__c'] >= session['Max_Participants__c'];

                let sessionName = session.Name;
                if(session.hasOwnProperty('Start_Date__c') && session.hasOwnProperty('End_Date__c')){
                    sessionName += ' – [';
                    sessionName += (new Date(session.Start_Date__c).getHours() < 10 ? '0' : '') + new Date(session.Start_Date__c).getHours();
                    sessionName += ':';
                    sessionName += (new Date(session.Start_Date__c).getMinutes() < 10 ?'0' : '') + new Date(session.Start_Date__c).getMinutes();
                    sessionName += ' - ';
                    sessionName += (new Date(session.End_Date__c).getHours() < 10 ? '0' : '') + new Date(session.End_Date__c).getHours();
                    sessionName += ':';
                    sessionName += (new Date(session.End_Date__c).getMinutes() < 10 ? '0' : '') + new Date(session.End_Date__c).getMinutes();
                    sessionName += ']';
                }

                if(session.hasOwnProperty('Mutual_Exclusion__c')){

                    if(!isDisabled){
                        displayedMutualExclusionSetIds.add(session['Mutual_Exclusion__c']); //for future validation
                    }

                    let radioButtonItem = {
                        Id: session.Id,
                        elementId: 'radio-session-'+uniqueIteration,
                        name: sessionName,
                        description: isDisabled ? 'Ausgebucht' : session['Description__c'],
                        mutualExclusion: session['Mutual_Exclusion__c'],
                        checked: this.selectedSessions.includes(session.Id) && !isDisabled,
                        isDisabled: isDisabled
                    };

                    if(mutualExclSessionsMap.hasOwnProperty(session['Mutual_Exclusion__c'])){
                        let radioButtonsItems = [...mutualExclSessionsMap[session['Mutual_Exclusion__c']]];
                        radioButtonsItems.push(radioButtonItem);
                        mutualExclSessionsMap[session['Mutual_Exclusion__c']] = radioButtonsItems;
                    } else {
                        mutualExclSessionsMap[session['Mutual_Exclusion__c']] = [radioButtonItem];
                    }

                } else {
                    let checkBoxItem = {
                        Id: session.Id,
                        elementId: 'checkbox-session-'+uniqueIteration,
                        name: sessionName,
                        description: isDisabled ? 'Ausgebucht' : session['Description__c'],
                        checked: this.selectedSessions.includes(session.Id) && !isDisabled,
                        isDisabled: isDisabled
                    };
                    checkboxValues.push(checkBoxItem);
                }

                uniqueIteration++;
            }

            for(let mutualExcl in mutualExclSessionsMap){
                let radioButton = {
                    values: mutualExclSessionsMap[mutualExcl]
                };
                radioButtons.push(radioButton);
            }

            accordion.day = date;
            accordion.sessions = {
                hasCheckboxes: checkboxValues.length > 0,
                hasRadioButtons: radioButtons.length > 0,
                checkboxValues: checkboxValues,
                radioButtons: radioButtons
            };

            accordionArray.push(accordion);
        }

        this.displayedMutualExclusionSetIds = displayedMutualExclusionSetIds;

        this.accordionArray = [...accordionArray];

        let sideEvents = [...this.sideEvents];
        let accordionSideEventArray = [];

        for(let i = 0; i < sideEvents.length; i++){
            accordionSideEventArray.push({
                Id: sideEvents[i].Id,
                elementId: 'checkbox-side-event-' + i,
                name: sideEvents[i].Name,
                description: sideEvents[i].hasOwnProperty('Start_Date__c') ? 'Start Date: '+Utils.formatDate(new Date(sideEvents[i]['Start_Date__c'])) : '',
                checked: this.selectedSideEvents.includes(sideEvents[i].Id)
            });
        }

        this.accordionSideEventArray = [...accordionSideEventArray];

    }
}