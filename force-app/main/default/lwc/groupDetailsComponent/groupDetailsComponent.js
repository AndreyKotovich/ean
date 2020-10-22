import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getGroupDetails from '@salesforce/apex/MyRegistrationsController.getGroupDetails'
import clickButton1Apex from '@salesforce/apex/MyRegistrationsController.clickButton1Apex'

export default class GroupDetailsComponent extends LightningElement {
	@api recordId;				// required for mode 'My Registrations'
	@api params;
	@api maxparticipants;		// required for mode 'Create Group Registration'

	_callbackResult;
	_callbackResultString = '';	// DELETE

	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_noRegistrationMessage = 'You have no registrations.'
	_isSpinner = true;
	_isError = false;

	_button1Label = 'Submit';
	_button2Label = 'Edit';

	_groupId = '';
	_groupName = '';
	_eventName = '';
	_eventEndDateString = '';
	_eventStartDateString = '';
	_eventEndTimeString = '';
	_eventStartTimeString = '';

	_registrationStatusOld = '';
	_registrationStatus = '';
	_totalGroupExistingParticipants = 0;
	_totalGroupMaxParticipants = 0;

	_displayGroupDetails = false;
	_displayGroupDefinition = true;
	_displayAccordions = false;
	_displayButton1 = false;
	_displayButton2 = false;

	_whereclause = '';
	_selitem = 'empty@nomail.com';
	_recordid = 'existingrecordid';

	_subGroupList;

	connectedCallback() {
		console.log('GroupDetailsComponent connectedCallback');
		console.log('this.recordId: ', this.recordId);

		getGroupDetails({settings: {
			params: this.params,
			groupId: this.recordId,
			maxParticipants: this.maxparticipants
			}}).then(result=>{
				console.log('result: ', result);
				this._callbackResult = result;
				this._callbackResultString = JSON.stringify(result);	// DELETE
				this._isError = false;
				this._isSpinner = false;

				this._groupId = result.groupDetails.groupId;
				this._groupName = result.groupDetails.groupName;
				this._eventName = result.groupDetails.eventName;
				this._eventEndDateString = result.groupDetails.eventEndDateString;
				this._eventStartDateString = result.groupDetails.eventStartDateString;
				this._eventEndTimeString = result.groupDetails.eventEndTimeString;
				this._eventStartTimeString = result.groupDetails.eventStartTimeString;
				this._registrationStatusOld = result.groupDetails.registrationStatus;
				this._registrationStatus = result.groupDetails.registrationStatus;
				this._totalGroupExistingParticipants = result.groupDetails.totalGroupExistingParticipants;
				this._totalGroupMaxParticipants = result.groupDetails.totalGroupMaxParticipants;

				this._displayGroupDetails = result.displayGroupDetails;
				this._displayGroupDefinition= result.displayGroupDefinition;
				this._displayAccordions = result.displayAccordions;

				this._displayButton1 = result.displayButton1;
				this._displayButton1 = result.displayButton2;
				this._button1Label = result.button1Label;
				this._button2Label = result.button2Label;

				this._subGroupList = result.subGroupList;
				// this._displayNoRegistrationMessage = result.displayNoRegistrationMessage;
			})
			.catch(error=>{
				console.log('GroupDetails component');
				console.log('getGroupDetails Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	handleToggleSection(event) {
		const openSections = event.detail.openSections;

		activeSectionsMessage = '';
        if (openSections.length === 0) {
            activeSectionsMessage = 'All sections are closed';
        } else {
            activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }

		console.log('handleToggleSection');
		console.log('activeSectionsMessage: ', activeSectionsMessage);
	}

	handleOngroupchangecontactemail(event) {
		const details1 = event.detail.recorddetails;
		const subGroupId = event.detail.uniquekey1;
		const participantIndex = event.detail.uniquekey2;
		// console.log('---------');
		// console.log('details1: ', details1);
		// console.log('subGroupId: ', subGroupId);
		// console.log('participantIndex: ', participantIndex);
		// console.log('---------');

		var participantDetails = event.detail.recorddetails ? JSON.parse(event.detail.recorddetails) : null;

		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== subGroupId) {
				continue;
			}

			var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));
			tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactId = participantDetails ? participantDetails.id : null;
			tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactEmail = participantDetails ? participantDetails.text : null;
			tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactName = participantDetails ? participantDetails.field2val : null;
			this._subGroupList = tempSubGroupList;

			// this._subGroupList[i].subGroupParticipantList[participantIndex].newContactId = participantDetails.id;
			// this._subGroupList[i].subGroupParticipantList[participantIndex].newContactEmail = participantDetails.text;
			// this._subGroupList[i].subGroupParticipantList[participantIndex].newContactName = participantDetails.field2val;

			// console.log('3333 this._subGroupList[i]: ', this._subGroupList[i]);
			// console.log('3333 this._subGroupList[i].subGroupParticipantList[participantIndex]: ', this._subGroupList[i].subGroupParticipantList[participantIndex]);
			// console.log('3333 this._subGroupList[i].subGroupParticipantList[participantIndex].newContactId: ', this._subGroupList[i].subGroupParticipantList[participantIndex].newContactId);
		}
	}

	//	Submit
	handleClickButton1() {
		console.log('handleClickButton1');

		clickButton1Apex({params: {
			// groupDetails: JSON.stringify(this.recordId),
			subGroupList: JSON.stringify(this._subGroupList),
			isGroupDefinitionMode: this._displayGroupDefinition
			}}).then(result=>{
				console.log('handleClickButton1 result: ', result);
				console.log('handleClickButton1 result.participantsString: ', result.participantsString);

				this.dispatchEvent(new CustomEvent('submitclick', { bubbles: true, detail: { participantsstring: result.participantsString} }));
			})
			.catch(error=>{
				console.log('GroupDetails component');
				console.log('clickButton1Apex Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	handleClickButton2() {
		console.log('handleClickButton2');
	}

	handleAccordionArrowClick(event) {
		var accordionIndex = event.currentTarget.dataset.id;
		console.log('accordionIndex: ', accordionIndex);

		var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));
		tempSubGroupList[accordionIndex].accordionIsExpanded = !tempSubGroupList[accordionIndex].accordionIsExpanded;
		this._subGroupList = tempSubGroupList;

		// console.log('111 this._subGroupList[accordionIndex].accordionIsExpanded: ', this._subGroupList[accordionIndex].accordionIsExpanded);
		// this._subGroupList[accordionIndex].accordionIsExpanded = !this._subGroupList[accordionIndex].accordionIsExpanded;
		// console.log('222 this._subGroupList[accordionIndex].accordionIsExpanded: ', this._subGroupList[accordionIndex].accordionIsExpanded);
	}



}