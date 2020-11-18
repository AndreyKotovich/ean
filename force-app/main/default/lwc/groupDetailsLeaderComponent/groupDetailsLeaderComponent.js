import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGroupDetails from '@salesforce/apex/GroupDetailsLeaderController.getGroupDetails'

export default class GroupDetailsLeaderComponent extends LightningElement {
	@api recordId;				// required

	_callbackResult;			// DELETE
	_callbackResultString = '';	// DELETE

	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_isSpinner = true;
	_isError = false;

	_invitedMessage = 'Succesfully Invited';
	_confirmedMessage = 'Succesfully Registered';

	_groupId = '';
	_eventId = '';
	_groupName = '';
	_eventName = '';
	_eventEndDateString = '';
	_eventStartDateString = '';
	_eventEndTimeString = '';
	_eventStartTimeString = '';
	_totalGroupExistingParticipants = 0;
	_totalGroupMaxParticipants = 0;

	_displayAccordions = false;
	_displayAddMoreTicketsButton = false;

	_whereclause = '';

	_subGroupList;

	_disabledEmails;
	_disabledEmailsThisGroup;
	_disabledEmailsString;

	connectedCallback() {
		this._isSpinner = true;
		this._isStep1 = false;

		getGroupDetails({params: {
			groupId: this.recordId
			}}).then(result=>{
				console.log('result: ', result);
				this._isSpinner = false;

				if (!result.result) {
					// console.log('result: ', result);
					this._isError = true;
					return;
				}

				this._isError = false;
				this._callbackResult = result;							// DELETE
				this._callbackResultString = JSON.stringify(result);	// DELETE

				this._groupId = result.groupDetails.groupId;
				this._groupName = result.groupDetails.groupName;
				this._eventName = result.groupDetails.eventName;
				this._eventId = result.groupDetails.eventId;
				this._eventEndDateString = result.groupDetails.eventEndDateString;
				this._eventStartDateString = result.groupDetails.eventStartDateString;
				this._eventEndTimeString = result.groupDetails.eventEndTimeString;
				this._eventStartTimeString = result.groupDetails.eventStartTimeString;
				this._totalGroupExistingParticipants = result.groupDetails.totalGroupExistingParticipants;
				this._totalGroupMaxParticipants = result.groupDetails.totalGroupMaxParticipants;

				this._displayAddMoreTicketsButton = result.displayAddMoreTicketsButton;
				this._subGroupList = result.subGroupList;

				this._disabledEmails = result.disabledEmails;
				this._disabledEmailsString = JSON.stringify(this._disabledEmails);
				this._disabledEmailsThisGroup = result.disabledEmailsThisGroup;
			})
			.catch(error=>{
				console.log('GroupDetailsLeaderComponent error: ', error);
				console.log('connectedCallback Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	handleAccordionArrowClick(event) {
		var accordionIndex = event.currentTarget.dataset.id;
		var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));
		tempSubGroupList[accordionIndex].accordionIsExpanded = !tempSubGroupList[accordionIndex].accordionIsExpanded;
		this._subGroupList = tempSubGroupList;

	}

	handleOngroupchangecontactemail(event) {
		console.log('handleOngroupchangecontactemail');
		const subGroupId = event.detail.uniquekey1;
		const participantIndex = event.detail.uniquekey2;
		const eventType = event.detail.eventtype;

		var participantDetails = event.detail.recorddetails ? JSON.parse(event.detail.recorddetails) : null;

		console.log('participantDetails: ', participantDetails);
		console.log('subGroupId: ', subGroupId);
		console.log('participantIndex: ', participantIndex);
		console.log('eventType: ', eventType);

		if (participantDetails.originalText == participantDetails.enteredText) return;

		// eventType === 'onblur' && 
		//	NOT VALID EMAIL
		if ((!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(participantDetails.enteredText)) || participantDetails.enteredText === '')) {
			console.log('NOT VALID EMAIL');
		}
		//	ironman@hotmail.com
		console.log('----------------------------');
		console.log('participantDetails.enteredText: ', participantDetails.enteredText);
		console.log('--');
		console.log('this._disabledEmailsThisGroup: ', this._disabledEmailsThisGroup);
		console.log('--');
		console.log('this._disabledEmails: ', this._disabledEmails);
		console.log('----------------------------');

		if(this._disabledEmailsThisGroup.includes(participantDetails.enteredText)) {
			console.log('includes in this._disabledEmailsThisGroup');
		}
		if(this._disabledEmails.includes(participantDetails.enteredText)) {
			console.log('includes in this._disabledEmails');
		}
		console.log('TEST');

		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== subGroupId) {
				continue;
			}

			var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));

			console.log('tempSubGroupList: ', tempSubGroupList);

			console.log('ZALUPA 0 INDEX: ', i);
			var currentParticipant = tempSubGroupList[i].subGroupParticipantList[participantIndex];

			if (participantDetails.enteredText === '') {
				console.log('ZALUPA 1 currentParticipant.errorInitial: ', currentParticipant.errorInitial);
				currentParticipant.buttonsSettings.displaySaveDraftButton = false;
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;

				console.log('ZALUPA 1_A');
				currentParticipant.error = JSON.parse(JSON.stringify(currentParticipant.errorInitial));
				console.log('ZALUPA 1_B');
				// is Order Paid
				if (currentParticipant.buttonsSettings.enableAddInviteButtons) currentParticipant.error.hasError = true;
				console.log('ZALUPA 11 currentParticipant.error: ', currentParticipant.error);
				console.log('ZALUPA 11 currentParticipant.errorInitial: ', currentParticipant.errorInitial);

			} else if ((!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(participantDetails.enteredText)) || participantDetails.enteredText === '')) {
				console.log('ZALUPA 2');
				currentParticipant.error.hasError = true;
				currentParticipant.error.message = 'Not valid email';
				console.log('ZALUPA 21');

			} else if (!this._disabledEmailsThisGroup.includes(participantDetails.enteredText) && this._disabledEmails.includes(participantDetails.enteredText)) {
				console.log('ZALUPA 3');
				currentParticipant.error.hasError = true;
				currentParticipant.error.message = 'Already registered on this event';
				console.log('ZALUPA 31');

			} else if (currentParticipant.oldContactEmail === participantDetails.enteredText) {
				console.log('ZALUPA 4 currentParticipant.errorInitial: ', currentParticipant.errorInitial);
				currentParticipant.error = currentParticipant.errorInitial;

				currentParticipant.buttonsSettings = currentParticipant.buttonsSettingsInitial;
				console.log('ZALUPA 41 currentParticipant.error: ', currentParticipant.error);

			} else {
				console.log('ZALUPA 100');
				currentParticipant.error.hasError = false;
				currentParticipant.error.message = '';
				console.log('ZALUPA 1001');
			}
			console.log('ZALUPA 200');
			tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;
			this._subGroupList = tempSubGroupList;
			console.log('ZALUPA 400');


			// tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactId = participantDetails ? participantDetails.id : null;
			// tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactEmail = participantDetails ? participantDetails.enteredText : null;
			// tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactName = participantDetails ? participantDetails.field2val : null;

			// var subGroupEnableSubmit = true;
			// for (var i2 = 0; i2 < tempSubGroupList[i].subGroupParticipantList.length; i2++) {
			// 	//	VALIDATE EMAIL
			// 	if (tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail == undefined || tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail == '') subGroupEnableSubmit = false;
			// 	if (tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail !== undefined ) {
			// 		if (!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail))) subGroupEnableSubmit = false;
			// 	}
			// }
			// tempSubGroupList[i].enableSubmitButton = subGroupEnableSubmit;
		}


	}

}