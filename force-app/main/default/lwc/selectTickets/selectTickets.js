import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Utils } from "c/utils";
import getEventTickets from "@salesforce/apex/EventRegistrationController.getEventTickets";

export default class SelectTickets extends LightningElement {
  @api eanEvent = {};
  @api userInfo = {};
  @api registrationType = "";

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

  @track isSpinner = true;
  @track ticketsRadio = [];
  @track _priceTicket = 0;
  @track _ticketsAmount = 0;

  hideNextButton = false;
  hidePreviousButton = false;
  allEventTickets = [];
  individualTickets = [];
  groupTickets = [];
  iprTickets = [];
  _selectedTicket = "";

  connectedCallback() {
    let promises = [
      getEventTickets({ eventId: this.eanEvent.Id })
    ];
    Promise.all(promises)
      .then((results) => {
        this.allEventTickets = [...results[0]];

        //ticket visibility rules
        for (let ticket of this.allEventTickets) {
          const {
            Is_Group_only__c,
            Is_IPR_only__c,
            Available_for_Countries__c,
            Available_for_Memberships__c
          } = ticket.Ticket__r;

          if (this.registrationType === "solo") {
            if (Is_Group_only__c || Is_IPR_only__c) continue;

            if (
              !Available_for_Countries__c ||
              !Available_for_Countries__c.includes(this.userInfo.countyRegion)
            )
              continue;

            if (!Available_for_Memberships__c) {
              this.individualTickets.push(ticket);
            } else {
              for (let membership of this.userInfo.memberships) {
                if (
                  Available_for_Memberships__c.includes(
                    membership.Membership__r.API__c
                  )
                ) {
                  this.individualTickets.push(ticket);
                  break;
                }
              }
            }
          } else if (this.registrationType === "group") {
            if (!Is_Group_only__c) continue;
            this.groupTickets.push(ticket);
          } else if (this.registrationType === "ipr") {
            if (!Is_IPR_only__c) continue;
            this.iprTickets.push(ticket);
          }
        }

        console.log("iprTickets: " + JSON.stringify(this.iprTickets));

        //radio compilation
        let ticketsRadio = [];

        let foundSelected = false;
        let tickets =
          this.registrationType === "solo"
            ? this.individualTickets
            : this.registrationType === "group"
            ? this.groupTickets
            : this.iprTickets;

        for (let i = 0; i < tickets.length; i++) {
          let price = this.getTicketPrice(tickets[i]);

          if (price === undefined) continue;

          ticketsRadio.push({
            elementId: "individual-ticket-radio-" + i,
            id: tickets[i].Id,
            name: tickets[i].Ticket__r.Name,
            price: price,
            checked: this._selectedTicket === tickets[i].Id
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

        this.isSpinner = false;
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
      });
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
    this._priceTicket = this.ticketsRadio.find(e => {
      return e.id === selectedTicket;
    }).price;
    this._selectedTicket = selectedTicket;
  }

  handlePreviousClick() {
    const selectEvent = new CustomEvent("previous", {
      detail: {}
    });
    this.dispatchEvent(selectEvent);
  }

  handleNextClick() {
    this.getSelectedTickets();
    let errorMessage = "";
    if (this._selectedTicket === "" && (errorMessage = "Select a ticket please") || this._ticketsAmount <= 0 && this.registrationType !== "solo" && (errorMessage = "Amount of ticket must more than 0")) {
      this.dispatchToast("Error", errorMessage, "error");
    } else {
      const selectEvent = new CustomEvent("continue", {
        detail: {
          selectedTicket: this._selectedTicket,
          priceTicket: this._priceTicket,
          ticketsAmount: this._ticketsAmount
        }
      });
      this.dispatchEvent(selectEvent);
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

  get isGroupRegistration() {
    return this.registrationType !== "solo";
  }

  handleSelectTicketsAmount(event) {
    this._ticketsAmount = event.detail.value;
  }

}