import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPicklistValues from "@salesforce/apex/EventRegistrationController.getPicklistValues";
import getEventTicketsLabels from "@salesforce/apex/EventRegistrationController.getEventTicketsLabels";
import getDiscountApex from "@salesforce/apex/DiscountHelper.getDiscount";
import { Utils } from "c/utils";
export default class ErSummarize extends LightningElement {

    @api
    get selections() {
        return this._selections;
    }
    set selections(value) {
        this._selections = Object.assign({}, value);
    }
    @api eanEvent = {};
    @api userInfo = {};

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
    // @track VATamount = 0;
    @track VATproc = 0;
    @track GrandTotalAmount = 0;
    @track vatNumber = '';
    isSolo = false;
    isUpgrade = false;
    isDiscount = false;
    isDates = false;
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
        let daysArray = getDaysArray(this.eanEvent.Start_Time__c, this.eanEvent.End_Time__c);
        if (daysArray.length === 0) {
            this.isDates = false;
        }
        return daysArray;
    }

    get selectedDates() {
        return this._selectedDates.length > 0 ? this._selectedDates : [];
    }

    connectedCallback() {
        this.VATproc = +this.eanEvent.VAT_Amount__c || 0;
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
        // this.isDates = this.isSolo && (!this._selections.eventParticipantConf || this._selections.eventParticipantConf === 0);
        this.isDates = false; 
        this.isDiscount = this.isSolo && (this.hasTickets || this.hasSessions);
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

                        let amount;

                        if(ticket.freeTicketAmount){
                            let rate = ticket.freeTicketAmount <= ticket.quantity ? ticket.quantity - ticket.freeTicketAmount : 0;
                            amount = ticket.amount * rate;
                        } else {
                            amount = ticket.amount * ticket.quantity;
                        }

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
                // this.VATamount = (+(this.totalAmountOrg * (1 + +this.VATproc / 100)).toFixed(2) - this.totalAmountOrg).toFixed(2);
                this.GrandTotalAmount = (+this.totalAmountOrg).toFixed(2);
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
        if(!this.nextValidation()) return;

        const selectEvent = new CustomEvent("continue", {
            detail: {
                discountInfo: this.discountInfo,
                selectedDates: this.selectedDates,
                // vatAmount: this.VATamount,
                vatNumber: this.vatNumber
            }
        });
        this.dispatchEvent(selectEvent);
    }

    nextValidation(){
        let result = true;
        let message = 'Something went wrong';

        result = Utils.validateElements.call(this, 'lightning-input');
        if(!result) message = 'Check your inputs';

        if(!result) this.dispatchToast('Error', message, 'error');

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

    сancelDiscount() {
        this.discountAmount = 0;
        this.totalAmount = this.totalAmountOrg;
        // this.VATamount = (+(this.totalAmountOrg * (1 + +this.VATproc / 100)).toFixed(2) - this.totalAmountOrg).toFixed(2);
        this.GrandTotalAmount = (+this.totalAmountOrg).toFixed(2);
        this.discountInfo = {};
    }

    getDiscount() {
        console.log('getDiscount START');
        this.discountAmount = 0;        
        // this.VATamount = 0;
        this.GrandTotalAmount = 0;
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
                // this.VATamount = (+(this.totalAmount * (1 + +this.VATproc / 100)).toFixed(2) - this.totalAmount).toFixed(2);
                this.GrandTotalAmount = (+this.totalAmount).toFixed(2);
                this.isSpinner = false;
            })
            .catch(error => {
                console.log('error ', error);
                this.discountAmount = 0;
                // this.VATamount = 0;
                this.GrandTotalAmount = 0;
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

    handleVatNumber(event){
        this.vatNumber = event.detail.value;
    }

    get VAT_Amount(){
        return (+this.GrandTotalAmount / (100 + +this.eanEvent.VAT_Amount__c) * +this.eanEvent.VAT_Amount__c).toFixed(2);
    }

}