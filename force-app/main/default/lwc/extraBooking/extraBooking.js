import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Utils } from "c/utils";
import getExtraSessions from "@salesforce/apex/EventRegistrationController.getExtraSessions";
import picklistValues from "@salesforce/apex/Utils.picklistValues";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class ExtraBooking extends LightningElement {
    @api eanEvent = {};
    @api userInfo = {};
    @api registrationType = "";
    @api hasOnlineTickets;

    @api
    get selectedSessions() {
        return this._selectedSessions;
    }
    set selectedSessions(value) {
        this._selectedSessions = value;
    }

    @api
    get selectedServices() {
        return this._selectedServices;
    }
    set selectedServices(value) {
        this._selectedServices = Object.assign({}, value);
    }

    @track hideNextButton = false;
    @track hidePreviousButton = false;
    @track isSpinner = true;
    @track sessionsCheckboxGroup = [];
    @track showSessions = true;
    @track newsletterLabel = "";

    eventExtraSessions = []; //all extra sessions for this event
    availableExtraSession = []; //sessions which are available for the participant
    isEarlyBird = false;
    _selectedSessions = [];
    _selectedServices = {};
    badgePicklistValues = [];

    @wire(getObjectInfo, { objectApiName: 'Contact' })
    objInfo({ data, error }) {
        if (data) this.newsletterLabel = data.fields.Newsletter__c.label;
    }

    connectedCallback() {
        console.log('hasOnlineTickets', this.hasOnlineTickets);
        this.hidePreviousButton = this.userInfo.isUpgrade;

        this.isEarlyBird = this.eanEvent.Early_Bird_Deadline__c ? Utils.deadlineCheck(this.eanEvent.Early_Bird_Deadline__c) : false;

        if (!this._selectedServices.hasOwnProperty('newsletter') && this.registrationType === 'solo') this._selectedServices.newsletter = this.userInfo.contact.Newsletter__c;

        let promise1 = getExtraSessions({ eventId: this.eanEvent.Id });
        let promise2 = picklistValues({ objectName: 'Participant__c', fieldName: 'Badge_Retrieval__c' });

        Promise.all([promise1, promise2])
            .then(results => {
                this.eventExtraSessions = results[0];
                this.badgePicklistValues = results[1];
                console.log('this.eventExtraSessions', this.eventExtraSessions)
                if (Object.keys(results[0]).length === 0 && results[0].constructor === Object) {
                    // this.handleNextClick();
                    this.showSessions = false;
                } else {
                    if (this.registrationType !== 'solo') {
                        this.showSessions = false;
                    } else {
                        this.parseSessionsAndPrice();
                    }
                }
                this.isSpinner = false;
            })
            .catch(error => {
                this.isSpinner = false;
                let message = '';
                if (error.body) {
                    if (error.body.message) {
                        message = error.body.message;
                    }
                }
                this.throwError({ message: message });
            })
    }

    handlePreviousClick() {
        const selectEvent = new CustomEvent("previous", {
            detail: {}
        });
        this.dispatchEvent(selectEvent);
    }

    handleNextClick() {
        console.log('handleNextClick');
        if (Utils.validateElements.call(this, '.validate-service')) {
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

    parseSessionsAndPrice() {
        //try{
        for (let session of this.eventExtraSessions) {

            if (!session.Event_Tickets__r) continue;
            console.log('session', session);
            let ticketCur = {};
            let ticketGroup = [];
            for (let ticket of session.Event_Tickets__r) {
                if (session.Id !== ticket.Session__c) continue;
                const { Available_for_Countries__c, Available_for_Memberships__c } = ticket.Ticket__r;

                if (!Available_for_Countries__c || !Available_for_Countries__c.includes(this.userInfo.countyRegion))
                    continue;
                ticket.price = this.isEarlyBird ? ticket.Early_bird_price__c : ticket.Price__c;
                
                if (this.userInfo.isUpgrade && this.userInfo.initiallySelectedSessions &&
                    this.userInfo.initiallySelectedSessions.length > 0) {
                    let rec = this.userInfo.initiallySelectedSessions.find(obj => obj.id === session.Id);
                    if (rec && (rec.price === ticket.Early_bird_price__c || rec.price === ticket.Price__c)) {
                        ticketCur = Object.assign({}, ticket);
                        ticket.isChecked = true;
                    }
                } else if (ticket.Participation__c && ticket.Participation__c === "Onsite") {
                    ticketCur = Object.assign({}, ticket);
                    ticket.isChecked = true;
                }

                if (!Available_for_Memberships__c) {
                    ticketGroup.push(ticket);
                } else {
                    for (let membership of this.userInfo.memberships) {
                        if (Available_for_Memberships__c.includes(membership.Membership__r.API__c)) {
                            ticketGroup.push(ticket);
                            break;
                        }
                    }
                }

            }

            if (Object.keys(ticketCur).length === 0) {
                ticketCur = Object.assign({}, session.Event_Tickets__r[0]);
            }
            ticketCur.ticketGroup = ticketGroup.length > 1 ? ticketGroup : [];
            console.log('ticketCur ', ticketCur);
            this.availableExtraSession.push(ticketCur);
        }
        // }
        // catch(e) {
        //     console.log('catch ', e);
        // }
        console.log('this.generateCheckboxGroup ');
        this.generateCheckboxGroup();
    }

    generateCheckboxGroup() {
        try {
            let sessionsCheckboxGroup = [];
            let selectedExclusions = [];
            console.log('availableExtraSession ', this.availableExtraSession);
            for (let session of this._selectedSessions) {
                let rec = this.availableExtraSession.find(obj => obj.Id === session.id);
                selectedExclusions.push(rec.Session__r.Mutual_Exclusion__c);
            }

            if (this.userInfo.isUpgrade &&
                this.userInfo.initiallySelectedSessions && this.userInfo.initiallySelectedSessions.length > 0) {

                for (let initialSelection of this.userInfo.initiallySelectedSessions) {
                    let rec = this.availableExtraSession.find(obj => obj.Session__c === initialSelection.id);
                    selectedExclusions.push(rec.Session__r.Mutual_Exclusion__c);
                }

            }

            for (let [i, ticket] of this.availableExtraSession.entries()) {

                const { Max_Participants__c, Registrations__c, Description__c, Name, Mutual_Exclusion__c } = ticket.Session__r;

                let price = this.isEarlyBird ? ticket.Early_bird_price__c : ticket.Price__c;
                if (price === undefined) continue;

                let isFull = Max_Participants__c ? Registrations__c >= Max_Participants__c : false;

                let isDisabled = isFull;

                let isChecked = !!this._selectedSessions.find(obj => obj.id === ticket.Id); //used only during init to auto populate

                if (this.userInfo.isUpgrade &&
                    this.userInfo.initiallySelectedSessions) {

                    let initiallySelectedSession = this.userInfo.initiallySelectedSessions.find(obj => obj.id === ticket.Session__c);
                    if (!!initiallySelectedSession) {
                        isChecked = true;
                        isDisabled = true;
                        price = initiallySelectedSession.price;
                    }

                }

                //disable mutual exclusions
                if (!isDisabled && Mutual_Exclusion__c && !isChecked) {
                    isDisabled = selectedExclusions.includes(Mutual_Exclusion__c);
                }

                sessionsCheckboxGroup.push({
                    elementId: `extra-session-${i}`,
                    value: ticket.Id,
                    sessionId: ticket.Session__c,
                    label: Name,
                    description: Description__c,
                    price: price,
                    exclusion: Mutual_Exclusion__c ? Mutual_Exclusion__c : "",
                    isDisabled,
                    isFull,
                    isChecked,
                    ticketGroup: ticket.ticketGroup,
                    isTicketGroup: ticket.ticketGroup.length > 0
                });
            }

            this.sessionsCheckboxGroup = [...sessionsCheckboxGroup];
        }
        catch (e) {
            console.log(' catch EEEE ', e);
        }
    }

    handleSelectSession(event) {
        let exclusion = event.target.dataset.exclusion;

        let validation = true;

        for (let checkbox of this.sessionsCheckboxGroup) {
            if (checkbox.value === event.target.value && checkbox.isDisabled) validation = false;
        }

        if (validation) {
            let disabledFlag = event.target.checked;

            for (let checkbox of this.sessionsCheckboxGroup) {
                if (checkbox.value === event.target.value && !checkbox.isFull) checkbox.isChecked = event.target.checked;

                if (exclusion === '' || checkbox.exclusion !== exclusion || checkbox.value === event.target.value || checkbox.isFull) continue;

                checkbox.isDisabled = disabledFlag;
            }
        }
    }

    handleSelectCategory(event) {
        let sessionId = event.target.dataset.session;
        console.log('sessionId ', sessionId);
        for (let checkbox of this.sessionsCheckboxGroup) {
            console.log('checkbox.value ', checkbox.value);
            if (checkbox.value === sessionId) {
                for (let ticket of checkbox.ticketGroup) {
                    ticket.isChecked = ticket.Id === event.target.dataset.id;
                }
                checkbox.price = event.target.dataset.price;
                console.log('checkbox ', JSON.parse(JSON.stringify(checkbox)));
            }
        }
    }

    getSelectedSessions() {
        let validatedSelectedSessions = [];

        for (let sessionCheckbox of this.sessionsCheckboxGroup) {
            if (!sessionCheckbox.isDisabled && sessionCheckbox.isChecked) {
                //need for isUpgrade mode
                let initialSelection = false;
                if (this.userInfo.initiallySelectedSessions) {
                    initialSelection = !!this.userInfo.initiallySelectedSessions.find(obj => obj.id === sessionCheckbox.sessionId);
                }
                if (sessionCheckbox.ticketGroup.length > 1) {
                    for (let ticket of sessionCheckbox.ticketGroup) {
                        if (ticket.isChecked) {
                            validatedSelectedSessions.push({
                                id: ticket.Id,
                                price: ticket.price,
                                isInitialSelection: initialSelection, //need for isUpgrade mode
                                sessionId: ticket.Session__c
                            });
                        }
                    }
                }
                else {
                    validatedSelectedSessions.push({
                        id: sessionCheckbox.value,
                        price: sessionCheckbox.price,
                        isInitialSelection: initialSelection, //need for isUpgrade mode
                        sessionId: sessionCheckbox.sessionId
                    });
                }
            }
        }

        this._selectedSessions = validatedSelectedSessions;
        return validatedSelectedSessions;
    }

    get badgeRetrievalOptions() {
        let options = [];
        let eventStartDay = Date.parse(this.eanEvent.Start_Time__c);
        let dateNow = new Date();
        dateNow.setDate(dateNow.getDate() + 10);

        for(let val of this.badgePicklistValues){
            if(val.value === 'pre_print'){
                if (dateNow.getTime() <= eventStartDay) options.push({ label: val.label, value: val.value });
            } else {
                options.push({ label: val.label, value: val.value });
            }
        }

        return options
    }

    get isBadgeRequired() {
        return this.eanEvent.RecordType.DeveloperName === 'Congress';
    }

    handleChangeBR(event) {
        if (!this.disableBadgeRetrieval) {
            this._selectedServices.badgeRetrieval = event.detail.value;
        }
    }

    handleChangeVL(event) {
        if (!this.disableVisaLetter) {
            this._selectedServices.visaLetter = event.detail.checked;
            console.log(JSON.stringify(this._selectedServices));
        }
    }

    get isGroupRegistration() {
        return this.registrationType !== 'solo';
    }

    handleChangeNewsletter(event) {
        if (!this.userInfo.contact.Newsletter__c) {
            this._selectedServices.newsletter = event.detail.checked;
        }
    }

    get disableBadgeRetrieval() {
        return this.userInfo.isUpgrade || !this.showOnsiteServices;
    }

    get disableVisaLetter() {
        return !this.showOnsiteServices;
    }

    get showOnsiteServices() {
        return !this.hasOnlineTickets;
    }

    get badgeRetrievalTooltip() {
        let result = '';

        if (!this.showOnsiteServices) {
            result = 'Available only for onsite tickets.';
        }

        return result;
    }
    get visaLetterTooltip() {
        let result = '';

        if (!this.showOnsiteServices) {
            result = 'Available only for onsite tickets.';
        }

        return result;
    }
}