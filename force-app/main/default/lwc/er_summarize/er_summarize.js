import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPicklistValues from "@salesforce/apex/EventRegistrationController.getPicklistValues";
import getEventTicketsLabels from "@salesforce/apex/EventRegistrationController.getEventTicketsLabels";
import getDiscountApex from "@salesforce/apex/DiscountHelper.getDiscount";
export default class ErSummarize extends LightningElement {
    // TODO skip step if there are no items

    @api
    get selections() {
        return this._selections;
    }
    set selections(value) {
        this._selections = Object.assign({}, value);
    }
    @api eanEvent = {};

    @track hasTickets = false;
    @track hasSessions = false;
    @track hideNextButton = false;
    @track hidePreviousButton = false;
    @track isSpinner = true;
    @track ticketsTable = [];
    @track sessionsTable = [];
    @track eventId;
    @track totalAmount = 0;
    @track discountAmount = 0;
    isSolo = false;
    isUpgrade = false;
    isDiscount = false;
    discountCode = '';
    totalAmountOrg = 0;
    discountInfo = {};
    _selections = {};
    badgePicklistValues = [];
    @track _selectedDates = [];
    get isApplyCoupon() {
        return Object.keys(this.discountInfo).length > 0;
    }

    get options() {
        let formatDateLabel = function (date) {
            let publishDate = new Date(date);
            return `${publishDate.getMonth() + 1}/${publishDate.getDate()}/${publishDate.getFullYear()}`;
        };

        let formatDateValue = function (date) {
            let publishDate = new Date(date);
            return `${publishDate.getFullYear()}-${publishDate.getMonth() + 1}-${publishDate.getDate()}`;
        };

        let getDaysArray = function (start, end) {
            let arr = [];
            //arr.push({ label: 'All', value: 'All'});
            for (let dt = new Date(Date.parse(start)); dt <= Date.parse(end); dt.setDate(dt.getDate() + 1)) {
                arr.push({ label: formatDateLabel(dt), value: formatDateValue(dt) });
            }
            return arr;
        };

        return getDaysArray(this.eanEvent.Start_Time__c, this.eanEvent.End_Time__c);
    }

    get selectedDates() {
        return this._selectedDates.length > 0 ? this._selectedDates : [];
    }

    connectedCallback() {
        let eventTicketsIds = [];
        if (this._selections.selectedTickets && this._selections.selectedTickets.length > 0) {
            this.hasTickets = true;

            for (let ticket of this._selections.selectedTickets) {
                eventTicketsIds.push(ticket.ticketId);
            }
        }

        if (this._selections.selectedSessions && this._selections.selectedSessions.length > 0) {
            this.hasSessions = true;

            for (let ticket of this._selections.selectedSessions) {
                eventTicketsIds.push(ticket.id);
            }
        }

        console.log('this._selections', JSON.parse(JSON.stringify(this._selections)));
        this.isSolo = this._selections.registrationType && this._selections.registrationType === 'solo';
        this.isUpgrade = this._selections.isUpgrade;
        this.isDates = this.isSolo && (!this._selections.eventParticipantConf || this._selections.eventParticipantConf === 0);
        this.isDiscount = this.hasTickets || this.hasSessions;
        this.eventId = this._selections.eventId;

        let promises = [
            getPicklistValues({ objectName: 'Participant__c', fieldName: 'Badge_Retrieval__c' }),
            getEventTicketsLabels({ eventTicketsIds: eventTicketsIds })
        ];

        Promise.all(promises)
            .then(results => {
                this.badgePicklistValues = [...results[0]];

                if (Object.keys(results[1]).length <= 0 && results[1].constructor === Object) {
                    this.hasTickets = false;
                    this.hasSessions = false;
                }
                if (this.hasTickets) {

                    for (let ticket of this._selections.selectedTickets) {
                        if (!results[1][ticket.ticketId]) continue;

                        let amount = ticket.amount * ticket.quantity;

                        this.ticketsTable.push(
                            {
                                id: ticket.ticketId,
                                name: results[1][ticket.ticketId],
                                quantity: ticket.quantity,
                                amount: amount,
                                ticketId: ticket.id
                            }
                        );

                        this.totalAmount += amount;
                    }

                }
                if (this.hasSessions) {
                    for (let session of this._selections.selectedSessions) {
                        if (!results[1][session.id]) continue;

                        this.sessionsTable.push(
                            {
                                id: session.id,
                                name: results[1][session.id],
                                quantity: 1,
                                amount: session.price,
                                sessionId: session.sessionId
                            }
                        );
                        this.totalAmount += session.price;
                    }
                }
                this.totalAmountOrg = this.totalAmount;
                console.log('ticketsTable', this.ticketsTable);
                console.log('sessionsTable', this.sessionsTable);
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
            });


    }

    handlePreviousClick() {
        const selectEvent = new CustomEvent("previous", {
            detail: {}
        });
        this.dispatchEvent(selectEvent);
    }

    handleNextClick() {
        const selectEvent = new CustomEvent("continue", {
            detail: {
                discountInfo: this.discountInfo,
                selectedDates: this.selectedDates
            }
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

    сancelDiscount() {
        this.discountAmount = 0;
        this.totalAmount = this.totalAmountOrg;
        this.discountInfo = {};
    }

    getDiscount() {
        console.log('getDiscount START');
        this.discountAmount = 0;
        this.totalAmount = this.totalAmountOrg;
        this.discountCode = this.template.querySelector('[data-id=dCode]').value;
        this.isSpinner = true;
        let sessionsTable = [];
        let ticketsTable = [];

        this.sessionsTable.forEach(e => {
            sessionsTable.push({ id: e.sessionId, amount: e.amount });
        });
        console.log('this.ticketsTable ', JSON.parse(JSON.stringify(this.ticketsTable)));
        this.ticketsTable.forEach(e => {
            ticketsTable.push({ id: e.ticketId, amount: e.amount });
        });

        let generalData = {
            eventId: this.eventId,
            sessions: sessionsTable,
            tickets: ticketsTable,
            discountCode: `${this.discountCode}`
        };

        console.log('generalData ', generalData);
        getDiscountApex({ generalData: generalData })
            .then(res => {
                console.log('res ', res);
                this.dispatchToast(res.status, res.message, res.status);
                if (res.status === 'Success') {
                    this.discountInfo = res.data;
                    if (this.discountInfo && this.discountInfo.sessions && this.discountInfo.sessions.length > 0) {
                        this.discountInfo.sessions.forEach(e => {
                            if (e && e.discountAmount) {
                                this.discountAmount -= +e.discountAmount;
                            }

                        });
                    }
                    if (this.discountInfo && this.discountInfo.tickets && this.discountInfo.tickets.length > 0) {
                        this.discountInfo.tickets.forEach(e => {
                            if (e && e.discountAmount) {
                                let tick = this.ticketsTable.find(item => `${item.ticketId}` === `${e.id}`);
                                let qnt = tick && tick.quantity ? tick.quantity : 1;
                                this.discountAmount -= +e.discountAmount;
                                e.discountAmount /= qnt;
                            }
                        });
                    }
                }
                this.totalAmount = this.totalAmountOrg + this.discountAmount;
                this.isSpinner = false;
            })
            .catch(error => {
                console.log('error ', error);
                this.discountAmount = 0;
                this.dispatchToast('Error', error, 'Error');
                this.isSpinner = false;
            });

    }

    get showBadgeRetrieval() {
        if (!this._selections.selectedServices) return false;
        return !!this._selections.selectedServices.badgeRetrieval;
    }

    get badgeRetrievalLabel() {
        let result = '';

        if (this.showBadgeRetrieval) {
            let picklistValue = this.badgePicklistValues.find(obj => obj.value === this._selections.selectedServices.badgeRetrieval);

            if (!!picklistValue) {
                result = picklistValue.label;
            }

        }

        return result;
    }

    get showVisaLetter() {
        if (!this._selections.selectedServices || !this._selections.selectedServices.visaLetter) return false;
        return this._selections.selectedServices.visaLetter;
    }

    get showNewsletter() {
        if (!this._selections.selectedServices || !this._selections.selectedServices.newsletter) return false;
        return this._selections.selectedServices.newsletter;
    }

    get showTotalAmount() {
        console.log(this.hasTickets || this.hasSessions);
        return this.hasTickets || this.hasSessions;
    }

    handleChangeDates(e) {
        // if (e.detail.value === 'All') {
        //     this._selectedDates = this.options.find(e => {  if (e.value !== 'All') { return e.value; } });
        // }
        // else {
        this._selectedDates = e.detail.value;
        // }
        console.log('this._selectedDates', this._selectedDates);
        console.log('this._selectedDates', JSON.parse(JSON.stringify(this._selectedDates)));
    }
}