import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Utils } from "c/utils";
import getEventTickets from "@salesforce/apex/EventRegistrationController.getEventTickets";
import getEventPersonaInfo from "@salesforce/apex/EventRegistrationController.getEventPersonaInfo";

export default class SelectTickets extends LightningElement {
    @api eanEvent = {};
    @api
    get userInfo() {
        return this._userInfo;
    }

    set userInfo(value) {
        this._userInfo = JSON.parse(JSON.stringify(value));
    }

    @api registrationType = "";

    @api markupSettings = {
        hidePreviousButton: false,
        nextButtonLabel: 'Next',
        hideNextButton: false,
        hideHeader: false
    }

    @api componentSize = {
        size: 12,
        largeDeviceSize: 4,
        mediumDeviceSize: 6,
        smallDeviceSize: 12
    }
    @api eventGroupInformation = {};

    @api
    get selectedTicket() {
        return this._selectedTicket;
    }

    set selectedTicket(value) {
        this._selectedTicket = value;
    }

    @api
    get priceTicket() {
        return this._priceTicket;
    }

    set priceTicket(value) {
        this._priceTicket = value;
    }

    @api
    get ticketsAmount() {
        return this._ticketsAmount;
    }

    set ticketsAmount(value) {
        this._ticketsAmount = value;
    }

    @api
    get groupIndividualTickets() {
        return this._groupIndividualTickets;
    }
    set groupIndividualTickets(value) {
        this._groupIndividualTickets = Object.assign({}, value);
    }

    @track isSpinner = true;
    @track ticketsRadio = []; // array with info for markup in solo registration
    @track ticketId = 0;
    @track _priceTicket = 0;
    @track _ticketsAmount = 0;
    @track availableParticipantNumber = 0;
    @track _groupIndividualTickets = {};
    @track isTicketTypeModal = false; //TODO AUTO POPULATE IT
    @track isGroupIndividual = false;

    // hideNextButton = false;
    allEventTickets = [];
    individualTickets = [];
    groupTickets = [];
    iprTickets = [];
    _selectedTicket = "";
    iprRegisteredParticipants = 0;
    _userInfo = {};

    connectedCallback() {
        if(this.registrationType === 'group'){
            if(this._groupIndividualTickets.isPartInit && this._groupIndividualTickets.participantsAmount > 0){
                this.individualGroupTickets();
            } else if(!!this._selectedTicket && this._ticketsAmount > 0) {
                this.contingentGroupTickets();
            } else {
                this.isTicketTypeModal = true;
            }
        }
        console.log('_userInfo', JSON.stringify(this._userInfo));
        if (this._userInfo.iprInfo && this._userInfo.iprInfo.participantAmount) {
            this.iprRegisteredParticipants = this._userInfo.iprInfo.participantAmount;
        }

        if (this.eanEvent.Max_Participants__c) {
            let availableParticipantNumber = this.eanEvent.Max_Participants__c - this.eanEvent.Registrations__c;
            this.availableParticipantNumber = availableParticipantNumber > 150 ? 150 : availableParticipantNumber;
        } else {
            this.availableParticipantNumber = 150;
        }

        let promises = [
            getEventTickets({ eventId: this.eanEvent.Id }),
            getEventPersonaInfo({ eventId: this.eanEvent.Id, contactId: this._userInfo.contact.Id })
        ];

        Promise.all(promises)
            .then((results) => {
                console.log('results: ' + JSON.stringify(results));
                this.allEventTickets = [...results[0]];
                this._userInfo.contactEventPersonaRoles = [...results[1]];
                return this.sortTicketsByRegType();
            })
            .then(() => {
                return this.markupTicketCompilation();
            })
            .catch((error) => {
                this.isSpinner = false;
                let message = "";
                if (error.body) {
                    if (error.body.message) {
                        message = error.body.message;
                    }
                }
                this.throwError({ message: message });
            })
            .finally(() => {
                this.isSpinner = false;
            })
    }

    sortTicketsByRegType() {
        new Promise((resolve) => {
            let ticketArr = [];
            this.groupTickets = [];
            for (let ticket of this.allEventTickets) {
                const {
                    Is_Group_only__c,
                    Is_IPR_only__c,
                    Available_for_Countries__c,
                    Available_for_Memberships__c,
                    Available_for_Personas__c
                } = ticket.Ticket__r;

                ticket.price = this.getTicketPrice(ticket);
                ticket.isChecked = ticket.Participation__c && ticket.Participation__c === "Onsite";
                if (this.registrationType === "solo") {
                    if (Is_Group_only__c || Is_IPR_only__c) continue;

                    if (!this.isTicketAvailableForPersona(ticket.Ticket__r)) {
                        continue;
                    } else {
                        if (!!Available_for_Personas__c) {
                            ticketArr.push(ticket);
                            // this.individualTickets.push(ticket);
                            continue;
                        }
                    }

                    if (!Available_for_Countries__c || !Available_for_Countries__c.includes(this._userInfo.countyRegion)) continue;

                    if (!Available_for_Memberships__c) {
                        ticketArr.push(ticket);
                        // this.individualTickets.push(ticket);
                    } else {
                        for (let membership of this._userInfo.memberships) {
                            if (
                                Available_for_Memberships__c.includes(
                                    membership.Membership__r.API__c
                                )
                            ) {
                                ticketArr.push(ticket);
                                // this.individualTickets.push(ticket);
                                break;
                            }
                        }
                    }

                } else if (this.registrationType === "group") {
                    if (!Is_Group_only__c) continue;
                    ticketArr.push(ticket);
                    // this.groupTickets.push(ticket);
                } else if (this.registrationType === "ipr") {
                    if (!Is_IPR_only__c) continue;
                    ticketArr.push(ticket);
                }
            }

            let ticketGroup = [];
            for (let tick of ticketArr) {
                let tik = ticketGroup.find(e => { return e.Id === tick.Ticket__c; });
                if (!tik) {
                    ticketGroup.push({ Id: tick.Ticket__c, tickets: [tick] });
                } else {
                    tik.tickets.push(tick);
                }
            }
            console.log('ticketGroup ', ticketGroup);
            ticketGroup.forEach(e => {
                let tik = e.tickets.find(el => { return el.Participation__c === "Onsite"; });
                let tick = Object.assign({}, tik || e.tickets[0]);
                tick.tickets = e.tickets.length > 1 ? e.tickets : [];
                if (this.registrationType === "solo") {
                    this.individualTickets.push(tick);
                }
                if (this.registrationType === "group") {
                    this.groupTickets.push(tick);
                }
                if (this.registrationType === "ipr") {
                    this.iprTickets.push(tick);
                }
            });

            console.log("iprTickets: " + JSON.stringify(this.iprTickets));
            resolve();
        });
    }

    handleSelectTicket(event) {
        this.ticketsRadio.forEach(e => {
            e.checked = false;
            if (e.id === event.target.value) {
                e.checked = true;
            }
        });
    }

    handleSelectCategory(event) {
        let ticketId = event.target.dataset.ticket;
        console.log('ticketId ', ticketId);
        for (let ticket of this.ticketsRadio) {

            console.log('ticket.Id ', ticket.id);
            if (ticket.id === ticketId) {
                for (let t of ticket.tickets) {
                    t.isChecked = t.Id === event.target.dataset.id;
                }
                ticket.id = event.target.dataset.id;
                ticket.price = +event.target.dataset.price;
                console.log('ticket ' , JSON.parse(JSON.stringify(ticket)));
            }
        }
    }

    markupTicketCompilation() {
        new Promise((resolve) => {
            let ticketsRadio = [];

            let foundSelected = false;
            let tickets =
                this.registrationType === "solo"
                    ? this.individualTickets
                    : this.registrationType === "group"
                        ? this.groupTickets
                        : this.iprTickets;
            console.log('tickets' , tickets)
            for (let i = 0; i < tickets.length; i++) {
                let price = this.getTicketPrice(tickets[i]);

                if (price === undefined) continue;

                ticketsRadio.push({
                    elementId: "individual-ticket-radio-" + i,
                    id: tickets[i].Id,
                    name: tickets[i].Ticket__r.Name,
                    tickedId: tickets[i].Ticket__c,
                    price: price,
                    checked: this._selectedTicket === tickets[i].Id,
                    tickets: tickets[i].tickets || [],
                    isTickets: tickets[i].tickets && tickets[i].tickets.length > 1
                });

                if (this._selectedTicket === tickets[i].Id) {
                    foundSelected = true;
                }
            }

            if (ticketsRadio.length > 0) {
                ticketsRadio[0].checked = true;
            }

            if (!foundSelected) this._selectedTicket = "";

            this.ticketsRadio = [...ticketsRadio];

            console.log('this.ticketsRadio', JSON.stringify(this.ticketsRadio));

            if (this.ticketsRadio.length === 0) {
                this.dispatchEvent(new CustomEvent("ticketsnotfound", {}));
            }
            resolve();
        })
    }

    isTicketAvailableForPersona(ticket) {
        let result = false;

        if (!!!ticket.Available_for_Personas__c) result = true;

        if (!result && ticket.Available_for_Personas__c && this._userInfo.contactEventPersonaRoles) {
            console.log('inside');
            console.log('inside', ticket.Available_for_Personas__c);
            console.log('inside2', this._userInfo.contactEventPersonaRoles);

            for (let role of this._userInfo.contactEventPersonaRoles) {
                if (ticket.Available_for_Personas__c.includes(role)) {
                    result = true;
                    break;
                }
            }
        }

        return result;
    }

    earlyBirdCheck() {
        let isEarlyBird = false;

        if (this.eanEvent.Early_Bird_Deadline__c) {
            let earlyBirdDeadline = Date.parse(this.eanEvent.Early_Bird_Deadline__c);
            let dateTimeNow = Date.now();

            if (earlyBirdDeadline >= dateTimeNow) {
                isEarlyBird = true;
            }
        }

        return isEarlyBird;
    }

    getTicketPrice(ticket) {
        return this.earlyBirdCheck() ? ticket.Early_bird_price__c : ticket.Price__c;
    }

    getSelectedTickets() {
        let selectedTicket = "";
        let priceTicket = 0;
        let checkedValues = this.template.querySelectorAll(
            ".input-ticket-radio:checked"
        );
        checkedValues.forEach((item) => {
            if (item.checked) {
                selectedTicket = item.value;
            }
        });

        console.log('selectedTicket ' , selectedTicket);
        let chosenTicket = this.ticketsRadio.find(e => {
            return e.id === selectedTicket;
        });
        console.log('chosenTicket ' , JSON.stringify(chosenTicket));
        this._priceTicket = chosenTicket.price;
        this.ticketId = chosenTicket.tickedId;
        console.log(selectedTicket);
        console.log(this._priceTicket);
        this._selectedTicket = selectedTicket;
    }

    handlePreviousClick() {
        const selectEvent = new CustomEvent("previous", {
            detail: {}
        });
        this.dispatchEvent(selectEvent);
    }

    handleNextClick() {
        if(this.showTicketsRadioGroup){
            this.getSelectedTickets();
        }

        if (this.nextClickValidation()) {
            let eventTicket = this.allEventTickets.find(obj => obj.Id === this._selectedTicket);
            console.log('eventTicket', JSON.stringify(eventTicket));
            let participantRole = '';
            let isOnlineTicket = eventTicket && eventTicket.Participation__c && eventTicket.Participation__c === 'Online';
            console.log('hasOnlineTickets', isOnlineTicket);

            if (this.registrationType === 'group') {
                participantRole = 'Group_Participant';
            } else if (this.registrationType === 'ipr') {
                participantRole = 'Exhibitor_Sponsor_IPR';
            } else if (this.registrationType === 'solo') {
                participantRole = 'Individual_Participant';
            }

            if (this.registrationType === 'solo' && !!eventTicket.Ticket__r.Available_for_Personas__c) {
                participantRole = 'Individual Participant';
                for (let role of this._userInfo.contactEventPersonaRoles) {
                    if (eventTicket.Ticket__r.Available_for_Personas__c.includes(role)) {
                        if (role === 'Press') participantRole = 'Press';
                        if (role === 'Invited_Person') participantRole = 'Invited_Persons';
                        if (role === 'Grant_Winner') participantRole = 'Scholarship_Bursaries';
                        if (role === 'Speaker') participantRole = 'Invited_Speaker';
                        break;
                    }
                }
            }

            const selectEvent = new CustomEvent("continue", {
                detail: {
                    selectedTicket: this._selectedTicket,
                    priceTicket: this._priceTicket,
                    ticketsAmount: this._ticketsAmount,
                    ticketId: this.ticketId,
                    participantRole: participantRole,
                    ticketName: !!eventTicket ? eventTicket.Ticket__r.Name : '',
                    groupIndividualTickets: this._groupIndividualTickets,
                    userInfo: this._userInfo,
                    freeAmount: this.registrationType === 'ipr' ? this.availableFreeIPRAmount : 0,
                    isOnlineTicket: isOnlineTicket
                }
            });
            this.dispatchEvent(selectEvent);
        }
    }

    nextClickValidation() {
        let result = true;
        let errorMessage = "";

        if (this.showTicketsRadioGroup && this._selectedTicket === "") {
            result = false;
            errorMessage = "Select a ticket please";
        }

        if (!Utils.validateElements.call(this, 'lightning-input')) {
            result = false;
            errorMessage = "Check your input";
        }

        if (result && this.isGroupRegistration && !!this.availableParticipantNumber && !!this._ticketsAmount) {
            result = parseInt(this._ticketsAmount) <= this.availableParticipantNumber;
            if (!result) {
                errorMessage = "You have selected too many participants";
            }
        }

        if (result && this.isGroupRegistration && !!this._groupIndividualTickets.participantsAmount && !!this.availableParticipantNumber) {
            result = parseInt(this._groupIndividualTickets.participantsAmount) <= this.availableParticipantNumber;
            if (!result) {
                errorMessage = "You have selected too many participants";
            }
        }

        if(result && this.registrationType === 'group' && !!!this.eventGroupInformation.Id){
            let amount = this.isGroupIndividual ? this._groupIndividualTickets.participantsAmount : this._ticketsAmount;
            result = parseInt(amount) >= 5;
            if(!result){
                errorMessage = "At least 5 tickets need to be selected";
            }
        }

        if (!result) this.dispatchToast("Error", errorMessage, "error");

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

    get isGroupRegistration() {
        return this.registrationType === "group" || this.registrationType === "ipr";
    }

    handleSelectTicketsAmount(event) {
        this._ticketsAmount = event.detail.value;
    }

    get inputLabel() {
        let str = 'Ticket Amount';

        if (this.availableParticipantNumber != null) {
            str += ' (max. ' + this.availableParticipantNumber + ' available)';
        }

        return str;
    }

    handleAddIndividualTickets(event) {
        console.log('handleAddIndividualTickets', event.detail.checked);
        this._groupIndividualTickets.isPartInit = event.detail.checked;
    }

    handleSelectIndividualTicketsAmount(event) {
        console.log('handleSelectIndividualTicketsAmount', event.detail.value);
        this._groupIndividualTickets.participantsAmount = event.detail.value;
    }

    get minGroupRegTicketAmount() {
        let res = 1;
        if (this._groupIndividualTickets.isPartInit) res = 0;
        return res;
    }

    get individualTicketAmountLabel() {
        let str = 'Individual ticket amount'

        if (this.availableParticipantNumber != null) {
            str += ' (max. ' + this.availableParticipantNumber + ' available)';
        }

        return str;
    }

    get isTicketAmountRequired() {
        return !this._groupIndividualTickets.isPartInit;
    }

    individualGroupTickets(){
        this.isGroupIndividual = true;
        this._groupIndividualTickets.isPartInit = true;
        this.isTicketTypeModal = false;
    }

    contingentGroupTickets(){
        this.isGroupIndividual = false;
        this.isTicketTypeModal = false;
    }

    get showTicketsRadioGroup(){
        let result = true;

        if(this.registrationType === 'group'){
            result = !this.isGroupIndividual;
        }

        return result;
    }

    get availableFreeIPRAmount(){
        let res  = 0;

        if(this.registrationType === 'ipr' && this._userInfo.iprInfo.ticketAmount){
            res = this._userInfo.iprInfo.ticketAmount - this.iprRegisteredParticipants;
        }

        return res;
    }

    get showFreeTicketSection(){
        return this.availableFreeIPRAmount > 0;
    }

    get atLeastWording(){
        return this.registrationType === 'group' && !!!this.eventGroupInformation.Id;
    }
}