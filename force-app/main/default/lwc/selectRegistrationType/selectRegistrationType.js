import {LightningElement, track, api} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import {Utils} from "c/utils";
import getContactIpr from "@salesforce/apex/EventRegistrationController.getContactIpr";
import existedParticipationCheck from "@salesforce/apex/EventRegistrationController.existedParticipationCheck";
import getRegistrationGroupById from "@salesforce/apex/EventRegistrationController.getRegistrationGroupById";

export default class SelectRegistrationType extends NavigationMixin(LightningElement) {
    @api
    get registrationType() {
        return this._selectedRegistrationType;
    }

    set registrationType(value) {
        this._selectedRegistrationType = value;
    }

    @api
    get eventGroupInformation() {
        return this._eventGroupInformation;
    }

    set eventGroupInformation(value) {
        this._eventGroupInformation = Object.assign({}, value);
    }

    @api eanEvent = {};
    @api userInfo = {};

    @track hideNextButton = false;
    @track hidePreviousButton = false;
    @track isSpinner = true;
    @track iprInfo = {};
    @track _selectedRegistrationType = "";
    @track groupInputLocked = false;

    // _groupName = "";
    MAX_GROUP_NAME_LENGTH = 80;
    existedParticipant = [];
    _eventGroupInformation = {};

    connectedCallback() {
        // this.defineGroupName();



        //GROUP id
        //Participant id
        let promises = [
            getContactIpr({contactId: this.userInfo.contact.Id, eventId: this.eanEvent.Id}),
            existedParticipationCheck({contactId: this.userInfo.contact.Id, eventId: this.eanEvent.Id})
        ];

        let urlParams = new URL(window.location);
        let groupId = urlParams.searchParams.get("gi");

        if(!!groupId){
            promises.push(getRegistrationGroupById({groupId: groupId}));
        }

        Promise.all(promises)
            .then(results => {
                let ipr = results[0];
                let existedParticipant = results[1];

                this.existedParticipant = existedParticipant;

                this.iprInfo = {
                    isIPR: ipr.length > 0,
                    ticketAmount: ipr.length > 0 ? ipr[0].Number_of_free_tickets__c : 0,
                    Id: ipr.length > 0 ? ipr[0].Id : "",
                    participantAmount: ipr.length > 0 && ipr[0].Event_Participations__r ? ipr[0].Event_Participations__r.length : 0
                }

                if(ipr.length > 0 && !this._eventGroupInformation.Name){
                    this._eventGroupInformation.Name = ipr[0].Account__r.Name.length > 80 ?
                        ipr[0].Account__r.Name.slice(0, this.MAX_GROUP_NAME_LENGTH) :
                        ipr[0].Account__r.Name;
                }

                if(!!groupId && results[2].length > 0){
                    this._eventGroupInformation = Object.assign({}, results[2][0]);
                    this.groupInputLocked = true;
                }

                if(this._selectedRegistrationType === ""){
                    this._selectedRegistrationType = this.registrationTypes[0].value;
                }

                if(existedParticipant.length > 0 && !!!this._eventGroupInformation.Id){
                    this.existedParticipantToast();
                }

                this.isSpinner = false;


            })
            .catch(error => {
                console.log(error);
                this.isSpinner = false;
                let message = "";
                if (error.body) {
                    if (error.body.message) {
                        message = error.body.message;
                    }
                }
                this.throwError({message: message});
            })
    }
    get registrationTypes() {
        let result = [];

        if(!!this._eventGroupInformation.Id){
            if(!!this._eventGroupInformation.Event_Exhibitor__c){
                result.push({label: "IPR registration", value: "ipr"});
            } else if(!!!this._eventGroupInformation.Event_Exhibitor__c) {
                result.push({label: "Group registration", value: "group"});
            }
        } else {
            if(this.existedParticipant.length === 0){
                result.push({label: "Solo registration", value: "solo"});
            }

            result.push({label: "Group registration", value: "group"});

            if(this.iprInfo.isIPR){
                result.push({label: "IPR registration", value: "ipr"});
            }
        }

        return result;
    }

    handlePreviousClick() {
        const selectEvent = new CustomEvent("previous", {
            detail: {}
        });
        this.dispatchEvent(selectEvent);
    }

    handleNextClick() {
        if (Utils.validateElements.call(this, "lightning-combobox, lightning-input")) {
            let obj = {
                registrationType: this._selectedRegistrationType,
                iprInfo: this.iprInfo
            };

            if(this.isGroupRegistration){
                if(this.registrationType === 'group' && !!!this._eventGroupInformation.Id){
                    if(this._eventGroupInformation.Event_Exhibitor__c){
                        delete this._eventGroupInformation.Event_Exhibitor__c;
                    }
                }

                if(this.registrationType === 'ipr' && !!!this._eventGroupInformation.Id){
                    this._eventGroupInformation.Event_Exhibitor__c = this.iprInfo.Id
                }

                obj.eventGroupInformation = this._eventGroupInformation;

            }

            const selectEvent = new CustomEvent("continue", {
                detail: obj
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

    handleSelectType(event) {
        this._selectedRegistrationType = event.detail.value;
        // this.defineGroupName();
    }

    existedParticipantToast(){
        if(this.existedParticipant.length > 0) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.existedParticipant[0].Id,
                    actionName: 'view',
                },
            }).then(url => {
                this.dispatchEvent(new ShowToastEvent({
                    "title": "Warning",
                    "message": "You are already registered for this event. See details {0}.",
                    "messageData": [
                        {
                            url: url,
                            label: 'here'
                        }
                    ],
                    "variant": "warning"
                }));
            });
        }
    }

    handleSelectGroupName(event) {
        if(!this.groupInputLocked){
            this._eventGroupInformation.Name = event.detail.value;
        }
    }

    get isGroupRegistration() {
        return this._selectedRegistrationType === "group" || this._selectedRegistrationType === "ipr";
    }

    // defineGroupName() {
    //     if (this.isGroupRegistration && this._groupName === "") {
    //         let urlParams = new URL(window.location);
    //         this._groupName = !!!urlParams.searchParams.get("gn")
    //             ? ""
    //             : urlParams.searchParams.get("gn");
    //     }
    // }
}