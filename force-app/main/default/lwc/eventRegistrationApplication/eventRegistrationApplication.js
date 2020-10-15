/* eslint-disable no-extra-boolean-cast */
import { LightningElement, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getUserMemberships from "@salesforce/apex/Utils.getUserMemberships";
import getEvent from "@salesforce/apex/EventRegistrationController.getEvent";
import getContactInfo from "@salesforce/apex/EventRegistrationController.getContactInfo";
import insertEventParticipants from "@salesforce/apex/EventRegistrationController.insertEventParticipants";
import insertRegistrationGroup from "@salesforce/apex/EventRegistrationController.insertRegistrationGroup";
import getCountries from "@salesforce/apex/membershipApplicationController.getCountries";

export default class EventRegistrationApplication extends NavigationMixin(LightningElement) {
    //TODO validation on duplicate registration
    //TODO detection group leader
    //TODO before participant insert check availability of participants

    @track errorMessage =
        "Something went wrong, please contact your system administrator.";
    @track isSpinner = true;
    @track isError = false;
    @track steps = {
        step1: {
            label: "Step 1",
            value: "step-1",
            isActive: true
        },
        step2: {
            label: "Step 2",
            value: "step-2",
            isActive: false
        }
    };
    @track progressIndicatorSteps = [];
    @track currentStep = null;
    @track ean_event = {};

    registrationType = "solo"; //type of registration which user selected, by default 'solo'
    groupName = ""; //name of group in case group registration
    selectedTicket = "";
    priceTicket = 0;
    ticketsAmount = 0;
    /**
     * @variable userInfo - information about user which works with the application
     * @property contact - contains contact record of user
     * @property memberships - active memberships of user (List<MembershipContactAssotiation__c>)
     * */
    userInfo = {};
    participants = {}; //event participants which we insert in database

    connectedCallback() {
        for (let prop in this.steps) {
            if (this.steps[prop]) {
                this.progressIndicatorSteps.push(this.steps[prop]);
            }
        }

        this.setCurrentStep();

        let urlParams = new URL(window.location);
        let eventId = urlParams.searchParams.get("ei");

        this.getInitialData(eventId)
            .catch((error) => {
                this.handleError(error);
            })
            .finally(() => {
                this.isSpinner = false;
            });
    }

    getInitialData(eventId) {
        let promises = [];

        promises.push(getEvent({ eventId: eventId }));
        promises.push(getContactInfo());
        promises.push(getUserMemberships());
        promises.push(getCountries());

        return new Promise((resolve, reject) => {
            Promise.all(promises)
                .then((results) => {
                    this.ean_event = Object.assign({}, results[0]);
                    console.log(JSON.stringify(results[1]));
                    this.userInfo = Object.assign({}, results[1]);
                    this.userInfo.memberships = [...results[2]];

                    //detect user region
                    if (!this.userInfo.contact.Residency__c)
                        reject({body: {message: "Can't detect user residency"}});

                    for (let country of results[3]) {
                        if (country.Country__c === this.userInfo.contact.Residency__c) {
                            this.userInfo.countyRegion = country.Region__c;
                            break;
                        }
                    }
                    console.log(JSON.stringify(this.userInfo));

                    resolve();
                })
                .catch((error) => {
                    reject(error);
                });
        });
    }

    setCurrentStep() {
        for (let prop in this.steps) {
            if (!this.steps[prop]) continue;

            if (this.steps[prop].isActive) {
                this.currentStep = this.steps[prop].value;
                break;
            }
        }
    }

    onNextRegType(event) {
        this.registrationType = event.detail.registrationType;
        this.groupName = event.detail.groupName;
        console.log(this.registrationType, this.groupName);
        this.onNext();
    }

    onSelectTicket(event) {
        this.selectedTicket = event.detail.selectedTicket;
        this.ticketsAmount = event.detail.ticketsAmount;
        this.priceTicket = event.detail.priceTicket;
        this.onNext();
    }

    onNext() {
        if (this.steps.step1.isActive) {
            this.steps.step1.isActive = false;
            this.steps.step2.isActive = true;
        } else if (this.steps.step2.isActive) {
            // this.steps.step2.isActive = false;
            this.finishRegistration();
        }
        this.setCurrentStep();
    }

    onPrevious() {
        if (this.steps.step2.isActive) {
            this.steps.step2.isActive = false;
            this.steps.step1.isActive = true;
        } else if (this.steps.step3.isActive) {
            this.steps.step3.isActive = false;
            this.steps.step2.isActive = true;
        }
        this.setCurrentStep();
    }

    finishRegistration() {
        this.isSpinner = true;
        let participants = [];
        let call = this.registrationType !== "solo" ?
            () => {
                return insertRegistrationGroup({ groupName: this.groupName, groupLeaderId: this.userInfo.contact.Id });
            } : () => { 
                return new Promise((resolve) => { resolve(); }); 
            };

        call()
            .then((result) => {
                console.log('in call');
                let generalData = {};
                generalData = {...generalData, ...this.userInfo};
                generalData.selectTicket = this.selectedTicket;
                generalData.event = this.ean_event;
                generalData.priceTicket = this.priceTicket;
                if (this.registrationType === "solo") {
                    participants.push({
                        sobjectType: "Participant__c",
                        Contact__c: this.userInfo.contact.Id,
                        Event_Ticket__c: this.userInfo.selectTicket,
                        Event_custom__c: this.ean_event.Id,
                    });
                } else {
                    for (let i = 0; i < this.ticketsAmount; i++) {
                        participants.push({
                            sobjectType: "Participant__c",
                            Event_custom__c: this.ean_event.Id,
                            Event_Ticket__c: this.userInfo.selectTicket,
                            Event_Registration_Sub_Group__c: result,
                        });
                    }
                }

                return insertEventParticipants({ participants: participants, generalData: generalData });
            })
            .then((res) => {
                this.isSpinner = false;
                let msg = res.status !== 'Error' ? `You have successfully registered for the ${this.ean_event.Name}` : res.message;
                this.dispatchToast(res.status, msg, res.status);

                if (res.status !== 'Error') {
                    this[NavigationMixin.Navigate]({
                        type: "comm__namedPage",
                        attributes: {
                            pageName: "home"
                        }
                    });
                }
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    onError(event) {
        let message = event.detail.message;
        if (event.detail.message) {
            if (event.detail.message !== "") {
                this.errorMessage = message;
            }
        }

        this.isError = true;
    }

    handleError(error) {
        console.log(JSON.stringify(error));
        this.isSpinner = false;
        if (error.body) {
            if (
                !error.body.hasOwnProperty("isUserDefinedException") &&
                error.body.hasOwnProperty("message")
            ) {
                this.errorMessage = error.body.message;
            }
        }
        this.isError = true;
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