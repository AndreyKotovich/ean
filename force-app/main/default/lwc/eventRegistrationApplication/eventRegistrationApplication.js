/* eslint-disable no-extra-boolean-cast */
import {LightningElement, track} from "lwc";
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import getUserMemberships from "@salesforce/apex/Utils.getUserMemberships";
import getEvent from "@salesforce/apex/EventRegistrationController.getEvent";
import getContactInfo from "@salesforce/apex/EventRegistrationController.getContactInfo";
import insertEventParticipants from "@salesforce/apex/EventRegistrationController.insertEventParticipants";
import insertRegistrationGroup from "@salesforce/apex/EventRegistrationController.insertRegistrationGroup";
import getCountries from "@salesforce/apex/membershipApplicationController.getCountries";
import updateContacts from "@salesforce/apex/EventRegistrationController.updateContacts";
import getParticipation from "@salesforce/apex/EventRegistrationController.getParticipation";
import updateParticipant from "@salesforce/apex/EventRegistrationController.updateParticipant";
import insertUpgradeData from "@salesforce/apex/EventRegistrationController.insertUpgradeData";

export default class EventRegistrationApplication extends NavigationMixin(LightningElement) {
    //TODO before participant insert check availability of participants
    //TODO create session participants
    //TODO participant available validation
    @track errorMessage = "Something went wrong, please contact your system administrator.";
    @track isSpinner = true;
    @track isError = false;
    @track steps = {
        step1: {
            label: "Registration type",
            value: "step-1",
            isActive: false
        },
        step2: {
            label: "Ticket selection",
            value: "step-2",
            isActive: false
        },
        step2_2:{
            label: "Participants Initialization",
            value: "step-2_2",
            isActive: false
        },
        step3: {
            label: "Extra booking",
            value: "step-3",
            isActive: false
        },
        step4: {
            label: "Summarize",
            value: "step-4",
            isActive: false
        }
    };
    @track progressIndicatorSteps = [];
    @track currentStep = null;
    @track ean_event = {};

    registrationType = ""; //type of registration which user selected
    eventGroupInformation = {}; //information about group during group registration
    selectedTicket = "";
    priceTicket = 0;
    ticketsAmount = 0;
    ticketId = 0;
    eventParticipantConf = 0;
    /**
     * @variable userInfo - information about user which works with the application
     * @property contact - contains contact record of user
     * @property memberships - active memberships of user (List<MembershipContactAssotiation__c>)
     * */
    userInfo = {};
    discountInfo = {};
    selectedDates = [];
    participants = {}; //event participants which we insert in database
    selectedSessions = []; //selected extra sessions
    selectedServices = { //selected extra services
        visaLetter: false,
        badgeRetrieval: ''
    };
    upgradeParticipant = {}; //participant in isUpgrade mode
    participantsInitialization={
        isPartInit: false,
        participantsAmount: 0,
        initializedParticipants: []
    };
    participantRole = '';
    eventPersonaId = ''; // id of record event persona or speaker
    freeTicketAmount = 0;
    hasOnlineTickets = false; // indicates if the any of selected tickets is online

    connectedCallback() {
        this.updateProgressBar();

        this.detectCurrentStep();

        let urlParams = new URL(window.location);
        let eventId = urlParams.searchParams.get("ei");
        let participantId = urlParams.searchParams.get("pi");

        this.getInitialData(eventId, participantId)
            .catch((error) => {
                this.handleError(error);
            })
            .finally(() => {
                this.isSpinner = false;
            });
    }

    updateProgressBar(){
        let progressIndicatorSteps = [];
        for (let prop in this.steps) {
            if(prop === 'step2_2' && (!!!this.registrationType || this.registrationType === 'solo')) continue;
            if (this.steps[prop]) {
                progressIndicatorSteps.push(this.steps[prop]);
            }
        }
        this.progressIndicatorSteps = [...progressIndicatorSteps];
    }

    getInitialData(eventId, participantId) {
        let promises = [];

        promises.push(getEvent({eventId: eventId}));
        promises.push(getContactInfo({contactId: null}));
        promises.push(getUserMemberships());
        promises.push(getCountries());
        if(!!participantId){
            promises.push(getParticipation({participantId: participantId}));
        } else {
            promises.push(new Promise((resolve)=>{resolve()}));
        }

        return new Promise((resolve, reject) => {
            Promise.all(promises)
                .then((results) => {
                    this.ean_event = Object.assign({}, results[0]);
                    console.log('11', JSON.stringify(results[1]));
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
                    console.log('111',JSON.stringify(this.userInfo));

                    this.setWizardStep('step-1');

                    if(!!results[4] && results[4].eventParticipant){
                        this.eventParticipantConf = results[4].eventParticipantConf;
                        if(this.userInfo.contact.Id !== results[4].eventParticipant.Contact__c) throw new Error();

                        this.upgradeParticipant = Object.assign({}, results[4].eventParticipant);
                        this.userInfo.isUpgrade = true;
                        this.selectedServices.visaLetter = results[4].eventParticipant.Visa_Letter__c;
                        this.selectedServices.badgeRetrieval = results[4].eventParticipant.Badge_Retrieval__c;
                        this.registrationType = 'solo';

                        if(results[4].sessionParticipation && results[4].sessionParticipation.length > 0){
                            let  initiallySelectedSessions = [];

                            for(let session of results[4].sessionParticipation){
                                initiallySelectedSessions.push({
                                    id: session.Session__c,
                                    price: session.Order_Items__r && session.Order_Items__r.length > 0 ? session.Order_Items__r[0].Amount__c : ''
                                });
                            }

                            this.userInfo.initiallySelectedSessions = initiallySelectedSessions;
                        }


                        console.log('this.userInfo', JSON.stringify(this.userInfo));
                        this.setWizardStep('step-3');
                    }

                    resolve();
                })
                .catch((error) => {
                    reject(error);
                });
        });
    }

    detectCurrentStep() {
        for (let prop in this.steps) {
            if (!this.steps[prop]) continue;

            if (this.steps[prop].isActive) {
                this.currentStep = this.steps[prop].value;
                break;
            }
        }
    }

    setWizardStep(step){
        for (let prop in this.steps) {
            if (this.steps[prop].value === step) {
                this.steps[prop].isActive = true;
                this.currentStep = this.steps[prop].value;
            } else {
                this.steps[prop].isActive = false;
            }
        }
    }

    resetData(){
        this.selectedTicket = "";
        this.ticketsAmount = 0;
        this.priceTicket = 0;
        this.ticketId = 0;
        this.participantsInitialization = {
            isPartInit: false,
            participantsAmount: 0,
            initializedParticipants: []
        };
        this.participantRole = '';
        this.eventPersonaId = '';
        this.selectedSessions = [];
        this.selectedServices = {
            visaLetter: false,
            badgeRetrieval: ''
        };
        this.discountInfo = {};
        this.selectedDates = [];
        this.participants = {};
        this.upgradeParticipant = {};
        this.freeTicketAmount = 0;
        this.hasOnlineTickets = false;
    }

    onNextRegType(event) {
        if(this.registrationType !== event.detail.registrationType){
            this.resetData();
        }
        this.registrationType = event.detail.registrationType;
        this.eventGroupInformation = Object.assign({}, event.detail.eventGroupInformation);
        console.log('eventGroupInformation', this.eventGroupInformation);
        this.userInfo.iprInfo = event.detail.iprInfo;
        this.updateProgressBar();
        this.onNext();
    }

    onSelectTicket(event) {
        console.log('1111 ', JSON.parse(JSON.stringify(event.detail)));
        this.selectedTicket = event.detail.selectedTicket;
        this.ticketsAmount = event.detail.ticketsAmount;
        this.priceTicket = event.detail.priceTicket;
        this.ticketId = event.detail.ticketId;
        console.log('event.detail.groupIndividualTickets', JSON.stringify(event.detail.groupIndividualTickets));
        this.participantsInitialization = event.detail.groupIndividualTickets;
        this.participantRole = event.detail.participantRole;
        this.eventPersonaId = event.detail.eventPersonaId;
        console.log('eventPersonaId', JSON.stringify(this.eventPersonaId));
        this.userInfo = event.detail.userInfo;
        this.freeTicketAmount = event.detail.freeAmount;
        this.hasOnlineTickets = event.detail.isOnlineTicket;
        this.onNext();
    }

    onParticipantInitialization(event){
        this.participantsInitialization = event.detail.participantsInitialization;

        for(let participant of this.participantsInitialization.initializedParticipants) {
            this.hasOnlineTickets = participant.isOnlineTicket;
            if(this.hasOnlineTickets) break;
        }

        this.onNext();
    }

    onExtraBooking(event) {
        this.selectedSessions = [...event.detail.selectedSessions];
        this.selectedServices = Object.assign({}, event.detail.selectedServices);
        console.log('selectedServices: '+JSON.stringify(event.detail.selectedServices));
        console.log('selectedSessions: '+JSON.stringify(event.detail.selectedSessions));

        //prep data for er_summarize component
        let selectedTickets = [];
        if(!!this.selectedTicket){
            if(this.registrationType === 'solo'){
                selectedTickets.push(
                    {
                        ticketId: this.selectedTicket,
                        quantity: 1,
                        amount: this.priceTicket,
                        id: this.ticketId
                    }
                );
            } else if(this.isGroupRegType && !!this.ticketsAmount) {
                selectedTickets.push(
                    {
                        ticketId: this.selectedTicket,
                        quantity: this.ticketsAmount,
                        amount: this.priceTicket,
                        id: this.ticketId,
                        freeTicketAmount: this.freeTicketAmount
                    }
                );
            }
        }

        if(this.registrationType === 'group' && this.participantsInitialization.isPartInit){
            let uniqTickets = {};

            for(let participant of this.participantsInitialization.initializedParticipants){

                if(uniqTickets[participant.selectedTicket] &&
                    uniqTickets[participant.selectedTicket].amount === participant.priceTicket &&
                    uniqTickets[participant.selectedTicket].id === participant.ticketId){

                    uniqTickets[participant.selectedTicket].quantity++;

                } else {
                    uniqTickets[participant.selectedTicket] = {
                        ticketId: participant.selectedTicket,
                        quantity: 1,
                        amount: participant.priceTicket,
                        id: participant.ticketId
                    };
                }
            }

            selectedTickets = selectedTickets.concat(Object.values(uniqTickets));
        }



        this.selections = {
            eventId: this.ean_event.Id,
            selectedTickets,
            selectedServices: this.selectedServices,
            selectedSessions: this.selectedSessions,
            registrationType: this.registrationType,
            isUpgrade: this.userInfo && this.userInfo.isUpgrade,
            eventParticipantConf: this.eventParticipantConf
        };

        //skip next step is there are no selected sessions and finish registration
        if( /*this.userInfo.isUpgrade && */ this.selectedSessions.length === 0 && this.eventParticipantConf > 0){
             this.finishRegistration();
        } else {
            this.onNext();
        }

    }

    onSummarize(event) {
        this.discountInfo = event.detail.discountInfo;
        this.selectedDates = event.detail.selectedDates;
        this.onNext();
    }

    onNext() {
        if (this.steps.step1.isActive) {
            this.steps.step1.isActive = false;
            this.steps.step2.isActive = true;
        } else if (this.steps.step2.isActive) {
            this.steps.step2.isActive = false;
            if(this.participantsInitialization.isPartInit && this.isGroupRegType){
                this.steps.step2_2.isActive = true;
            } else {
                this.steps.step3.isActive = true;
            }
        } else if (this.steps.step2_2.isActive){
            this.steps.step2_2.isActive = false;
            this.steps.step3.isActive = true;
        } else if (this.steps.step3.isActive) {
            this.steps.step3.isActive = false;
            this.steps.step4.isActive = true;
        } else if (this.steps.step4.isActive) {
            // this.steps.step2.isActive = false;
            this.finishRegistration();
        }
        this.detectCurrentStep();
    }

    onPrevious() {
        if (this.steps.step2.isActive) {
            this.steps.step2.isActive = false;
            this.steps.step1.isActive = true;
        } else if (this.steps.step2_2.isActive) {
            this.steps.step2_2.isActive = false;
            this.steps.step2.isActive = true;
        } else if (this.steps.step3.isActive) {
            this.steps.step3.isActive = false;
            if(this.participantsInitialization.isPartInit && this.isGroupRegType){
                this.steps.step2_2.isActive = true;
            } else {
                this.steps.step2.isActive = true;
            }
        } else if (this.steps.step4.isActive) {
            this.steps.step4.isActive = false;
            this.steps.step3.isActive = true;
        }
        this.detectCurrentStep();
    }

    finishRegistration(){
        if(this.userInfo.isUpgrade){
            this.onFinishUpgrade();
        } else {
            this.onFinishRegistration();
        }
    }

    onFinishRegistration() {
        this.isSpinner = true;
        let participants = [];
        let call = this.registrationType !== "solo" ?
            () => {
                return insertRegistrationGroup({eventGroupInformation: this.eventGroupInformation, groupLeaderId: this.userInfo.contact.Id});
            } : () => {
                return new Promise((resolve) => {
                    resolve();
                });
            };

        call()
            .then((result) => {
                console.log('in call');
                let generalData = {};
                generalData = {...generalData, ...this.userInfo};
                generalData.selectTicket = this.selectedTicket;
                generalData.eventId = this.ean_event.Id;
                generalData.priceTicket = this.priceTicket;
                generalData.contactId = this.userInfo.contact.Id;
                generalData.discountInfo = this.discountInfo;
                generalData.selectedDates = this.selectedDates;

                console.log('generalData', JSON.parse(JSON.stringify(generalData)));

                let participantPriceArr = [];

                if (this.registrationType === "solo") {
                    participantPriceArr.push({
                        participant: {
                            sobjectType: "Participant__c",
                            Contact__c: this.userInfo.contact.Id,
                            Event_Ticket__c: generalData.selectTicket,
                            Event_custom__c: this.ean_event.Id,
                            Badge_Retrieval__c: this.selectedServices.badgeRetrieval ? this.selectedServices.badgeRetrieval : '',
                            Visa_Letter__c: this.selectedServices.visaLetter,
                            Status__c: 'Pending',
                            Role__c: this.participantRole,
                            Lecture_Presentation__c: this.participantRole === 'Invited_Speaker' ? this.eventPersonaId : '',
                            Event_Persona__c: !!this.participantRole && this.participantRole !== 'Invited_Speaker' ? this.eventPersonaId : ''
                        },
                        price: this.priceTicket
                    });
                } else {
                    generalData.groupId = result;
                    for (let i = 0; i < this.ticketsAmount; i++) {
                        let obj = {
                            sobjectType: "Participant__c",
                            Event_custom__c: this.ean_event.Id,
                            Event_Ticket__c: generalData.selectTicket,
                            Event_Registration_Sub_Group__c: result,
                            Badge_Retrieval__c: this.selectedServices.badgeRetrieval ? this.selectedServices.badgeRetrieval : '',
                            Visa_Letter__c: this.selectedServices.visaLetter,
                            Status__c: 'Pending',
                            Role__c: this.participantRole
                        }

                        if(this.registrationType === 'ipr'){
                            obj.Event_Exhibitor__c = this.userInfo.iprInfo.Id
                        }

                        let price = this.freeTicketAmount > 0 && i+1 <= this.freeTicketAmount ? 0 : this.priceTicket;

                        participantPriceArr.push({
                            participant: obj,
                            price: price
                        });
                    }

                    for(let participant of this.participantsInitialization.initializedParticipants){
                        participantPriceArr.push({
                            participant: {
                                sobjectType: "Participant__c",
                                Event_custom__c: this.ean_event.Id,
                                Event_Ticket__c: participant.selectedTicket,
                                Event_Registration_Sub_Group__c: result,
                                Badge_Retrieval__c: this.selectedServices.badgeRetrieval ? this.selectedServices.badgeRetrieval : '',
                                Visa_Letter__c: this.selectedServices.visaLetter,
                                Status__c: 'Pending',
                                Contact__c: participant.contact.Id ? participant.contact.Id : '',
                                Role__c: participant.participantRole,
                                Lecture_Presentation__c: !!participant.participantRole && participant.participantRole === 'Invited_Speaker' ? participant.eventPersonaId : '',
                                Event_Persona__c: !!participant.participantRole && participant.participantRole !== 'Invited_Speaker' ? participant.eventPersonaId : ''
                            },
                            price: participant.priceTicket
                        });
                    }
                }
                console.log('participantPriceArr', participantPriceArr)

                let promiseArray = [];
                promiseArray.push(insertEventParticipants({participantPriceMap: participantPriceArr, generalData: generalData, selectedSession: this.selectedSessions}));

                if(this.registrationType === 'solo'){
                    let updateContact = [{sobjectType: "Contact", Id: this.userInfo.contact.Id, Newsletter__c: this.selectedServices.newsletter}];
                    promiseArray.push(updateContacts({contacts: updateContact}));
                } else {
                    promiseArray.push(new Promise((resolve)=>{
                        resolve({status: 'Success'})
                    }));
                }
                return Promise.all(promiseArray);
            })
            .then(([data, data2]) => {
                this.isSpinner = false;
                let msg = data.status !== 'Error' ? `You have successfully registered for the ${this.ean_event.Name}` : data.message;
                this.dispatchToast(data.status, msg, data.status);

                console.log('data2', JSON.stringify(data2));
                if(data2.status === 'Error'){
                    this.dispatchToast(data2.status, data2.message, data2.status);
                }

                console.log('data insertEventParticipants ', data);

                if (data.status !== 'Error') {
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'payment-component'
                        },
                        state: {
                            orderId: data.result[0].Id
                        }
                    });
                }

            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    onFinishUpgrade(){
        this.isSpinner = true;
        let participant = {
            Id: this.upgradeParticipant.Id,
            Visa_Letter__c: this.selectedServices.visaLetter
        };

        let updateContact = [{sobjectType: "Contact", Id: this.userInfo.contact.Id, Newsletter__c: this.selectedServices.newsletter}];

        let insertData = {}

        //if(this.selectedSessions.length > 0){
            let generalData = {};
            generalData = {...generalData, ...this.userInfo};
            generalData.selectTicket = this.selectedTicket;
            generalData.eventId = this.ean_event.Id;
            generalData.priceTicket = this.priceTicket;
            generalData.contactId = this.userInfo.contact.Id;
            generalData.discountInfo = this.discountInfo;
            generalData.selectedDates = this.selectedDates;

            Object.assign(insertData, {participant: this.upgradeParticipant.Id, selectedSessions:this.selectedSessions, generalData})
            console.log('insertData', JSON.stringify(insertData));
        //}

        Promise.all([
            updateParticipant({participant: participant}),
            updateContacts({contacts: updateContact}),
            Object.keys(insertData).length > 0 ? insertUpgradeData({data: insertData}) : new Promise(resolve => {resolve({status: 'Success'})})
        ])
            .then(([res1, res2, res3])=>{
                this.isSpinner = false;

                if(res2.status === 'Error'){
                    this.dispatchToast(res2.status, res2.message, res2.status);
                }

                let msg = res3.status !== 'Error' ? 'You have successfully upgraded your registration' : res3.message;
                this.dispatchToast(res3.status, msg, res3.status);

                if(res3.status !== 'Error'){

                    if(res3.result && this.selectedSessions.length > 0){
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'payment-component'
                            },
                            state: {
                                orderId: res3.result[0].Id
                            }
                        });
                    } else {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.upgradeParticipant.Id,
                                actionName: 'view',
                            },
                        });
                    }

                }

            })
            .catch(error=>{
                this.handleError(error);
            })

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

    get isGroupRegType(){
        return this.registrationType === 'group' || this.registrationType === 'ipr';
    }
}