import {LightningElement, track, api} from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Utils } from "c/utils";
import getExtraSessions from "@salesforce/apex/EventRegistrationController.getExtraSessions";

export default class ExtraBooking extends LightningElement {
    @api eanEvent = {};
    @api userInfo = {};
    @api registrationType = "";

    @api
    get selectedSessions() {
        return this._selectedSessions;
    }
    set selectedSessions(value) {
        this._selectedSessions = value;
    }

    @api
    get selectedServices(){
        return this._selectedServices;
    }
    set selectedServices(value){
        this._selectedServices = value;
    }

    @track hideNextButton = false;
    @track hidePreviousButton = false;
    @track isSpinner = true;
    @track sessionsCheckboxGroup = [];

    eventExtraSessions = []; //all extra sessions for this event
    availableExtraSession = []; //sessions which are available for the participant
    isEarlyBird = false;
    _selectedSessions = [];
    _selectedServices = {};

    connectedCallback() {
        if (this.registrationType !== "solo") return this.handleNextClick();

        this.isEarlyBird = this.eanEvent.Early_Bird_Deadline__c ? Utils.deadlineCheck(this.eanEvent.Early_Bird_Deadline__c) : false;

        let promise1 = getExtraSessions({eventId: this.eanEvent.Id});

        Promise.all([promise1])
            .then(results =>{
                this.eventExtraSessions = results[0];

                if(this.registrationType === 'group' || Object.keys(results[0]).length === 0 && results[0].constructor === Object){
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

        if(Utils.validateElements.call(this, '.validate-service')){
            const selectEvent = new CustomEvent("continue", {
                detail: {
                    selectedSessions: this.getSelectedSessions(),
                    selectedServices: this._selectedServices
                }
            });
            this.dispatchEvent(selectEvent);
        } else {
            this.dispatchToast('Error', 'Complete all required fields', 'error');
        }

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
        let selectedExclusions = [];

        for(let session of this._selectedSessions){
            let rec = this.availableExtraSession.find(obj => obj.Id === session.id);
            selectedExclusions.push(rec.Session__r.Mutual_Exclusion__c);
        }

        for(let [i, ticket] of this.availableExtraSession.entries()){

            const { Max_Participants__c, Registrations__c, Description__c, Name, Mutual_Exclusion__c } = ticket.Session__r;

            let price = this.isEarlyBird ? ticket.Early_bird_price__c : ticket.Price__c;
            if(price === undefined) continue;

            let isFull = Max_Participants__c ? Registrations__c >= Max_Participants__c : false;

            let isChecked = !!this._selectedSessions.find(obj => obj.id === ticket.Id ); //used only during init to auto populate

            let isDisabled = isFull;
            if(!isDisabled && Mutual_Exclusion__c && !isChecked){
                isDisabled = selectedExclusions.includes(Mutual_Exclusion__c);
            }

            sessionsCheckboxGroup.push({
                elementId: 'extra-session-'+i,
                value: ticket.Id,
                label: Name,
                description: Description__c,
                price: price,
                exclusion: Mutual_Exclusion__c ? Mutual_Exclusion__c : "",
                isDisabled,
                isFull,
                isChecked
            });
        }

        this.sessionsCheckboxGroup = [...sessionsCheckboxGroup];
    }

    handleSelectSession(event){
        let exclusion = event.target.dataset.exclusion;

        let validation = true;

        for(let checkbox of this.sessionsCheckboxGroup){
            if(checkbox.value === event.target.value && checkbox.isDisabled) validation = false;
        }

        if(exclusion !== '' && validation){
            let disabledFlag = event.target.checked;

            for(let checkbox of this.sessionsCheckboxGroup){
                if(checkbox.value === event.target.value && !checkbox.isFull) checkbox.isChecked = event.target.checked;

                if(checkbox.exclusion !== exclusion || checkbox.value === event.target.value || checkbox.isFull) continue;

                checkbox.isDisabled = disabledFlag;
            }
        }
    }

    getSelectedSessions(){
        let validatedSelectedSessions = [];

        for(let sessionCheckbox of this.sessionsCheckboxGroup){
            if(!sessionCheckbox.isDisabled && sessionCheckbox.isChecked){
                validatedSelectedSessions.push({
                    id: sessionCheckbox.value,
                    price: sessionCheckbox.price
                });
            }
        }

        this._selectedSessions = validatedSelectedSessions;
        return validatedSelectedSessions;
    }

    get badgeRetrievalOptions(){
        let options = [];
        let eventStartDay = Date.parse(this.eanEvent.Start_Time__c);
        let dateNow = new Date();
        dateNow.setDate(dateNow.getDate() + 10);

        if(dateNow.getTime() <= eventStartDay){
            options.push({ label: 'Pre-print by EAN', value: 'pre_print'});
        }

        options.push({ label: 'Onsite print', value: 'onsite' });

        return options
    }

    get isBadgeRequired(){
        return this.eanEvent.RecordType.DeveloperName === 'Congress';
    }

    handleChangeBR(event){
        this._selectedServices.badgeRetrieval = event.detail.value;
    }

    handleChangeVL(event){
        this._selectedServices.visaLetter = event.detail.checked;
        console.log(JSON.stringify(this._selectedServices));
    }

    get isGroupRegistration(){
        return this.registrationType !== 'solo';
    }

    handleJournalSelect(event){
        this._selectedServices.journals = [...event.detail.selectedProducts];
        console.log(JSON.stringify(this._selectedServices));
    }
}