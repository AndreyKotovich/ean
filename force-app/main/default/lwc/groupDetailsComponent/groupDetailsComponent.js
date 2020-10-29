import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGroupDetails from '@salesforce/apex/GroupDetailsController.getGroupDetails'
import clickSubmitRegistrationFlow from '@salesforce/apex/GroupDetailsController.clickSubmitRegistrationFlow'
import clickSubmitSubGroupParticipants from '@salesforce/apex/GroupDetailsController.clickSubmitSubGroupParticipants'

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

	_groupId = '';
	_eventId = '';
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
	_displayGroupDetailsPartial = false;
	_displayGroupDefinition = true;
	_displayAccordions = false;
	_displayGroupDetailsCancelButton = false;
	_displayFinalCancel = false;
	_displayRegistrationSubmit = false;
	_displayAddMoreTicketsButton = false;

	_whereclause = '';
	_selitem = 'empty@nomail.com';
	_recordid = 'existingrecordid';

	_subGroupList;

	_disabledEmails;
	_disabledEmailsString;

	_isChangeRequestMode = false;

	_displayTransferContainer = false;
	_tempParticipant = {};
	_displayTransferFinalNextButton = false;
	_requestedContactId = '';
	_requestedContactEmail = '';
	_requestedContactName = '';
	_displayFinalSubmitTransferButton = false;

	_additionalIconsStyle = ' margin-top: -2px;';

	connectedCallback() {
		console.log('GroupDetailsComponent connectedCallback');
		console.log('this.recordId: ', this.recordId);
		this._isSpinner = true;
		this._displayFinalSubmitTransferButton = false;

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
				this._eventId = result.groupDetails.eventId;
				this._eventEndDateString = result.groupDetails.eventEndDateString;
				this._eventStartDateString = result.groupDetails.eventStartDateString;
				this._eventEndTimeString = result.groupDetails.eventEndTimeString;
				this._eventStartTimeString = result.groupDetails.eventStartTimeString;
				this._registrationStatusOld = result.groupDetails.registrationStatus;
				this._registrationStatus = result.groupDetails.registrationStatus;
				this._totalGroupExistingParticipants = result.groupDetails.totalGroupExistingParticipants;
				this._totalGroupMaxParticipants = result.groupDetails.totalGroupMaxParticipants;

				this._displayGroupDetails = result.displayGroupDetails;
				this._displayGroupDetailsPartial = result.displayGroupDetailsPartial;
				this._displayGroupDefinition= result.displayGroupDefinition;
				this._displayAccordions = result.displayAccordions;

				this._isChangeRequestMode = result.isChangeRequestMode;

				this._displayFinalCancel = result.displayFinalCancel;
				this._displayRegistrationSubmit = result.displayRegistrationSubmit;
				this._displayAddMoreTicketsButton = result.displayAddMoreTicketsButton;

				this._subGroupList = result.subGroupList;
				this._disabledEmails = result.disabledEmails;
				this._disabledEmailsString = JSON.stringify(this._disabledEmails);
				// this._displayNoRegistrationMessage = result.displayNoRegistrationMessage;

				this._tempParticipant = {};
			})
			.catch(error=>{
				console.log('GroupDetails component');
				console.log('getGroupDetails Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	handleOngroupchangecontactemail(event) {
		console.log('handleOngroupchangecontactemail');
		const subGroupId = event.detail.uniquekey1;
		const participantIndex = event.detail.uniquekey2;

		var participantDetails = event.detail.recorddetails ? JSON.parse(event.detail.recorddetails) : null;
		this._displayGroupDetailsCancelButton = true;

		console.log('participantDetails: ', participantDetails);

		if (participantDetails.originalText == participantDetails.enteredText) return;

		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== subGroupId) {
				continue;
			}

			var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));
			tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactId = participantDetails ? participantDetails.id : null;
			// tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactEmail = participantDetails ? participantDetails.text : null;
			tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactEmail = participantDetails ? participantDetails.enteredText : null;
			tempSubGroupList[i].subGroupParticipantList[participantIndex].newContactName = participantDetails ? participantDetails.field2val : null;

			var subGroupEnableSubmit = true;
			for (var i2 = 0; i2 < tempSubGroupList[i].subGroupParticipantList.length; i2++) {
				//	VALIDATE EMAIL
				if (tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail == undefined || tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail == '') subGroupEnableSubmit = false;
				if (tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail !== undefined ) {
					if (!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail))) subGroupEnableSubmit = false;
				}
			}
			tempSubGroupList[i].enableSubmitButton = subGroupEnableSubmit;
			this._subGroupList = tempSubGroupList;
		}
		if (participantDetails.originalText != '') this.removeEmailFromDisabledEmails(participantDetails.originalText);
		if (participantDetails.enteredText != '') this.addEmailToDisabledEmails(participantDetails.enteredText);
	}

	handleSubmitSubGroupParticipants(event) {
		console.log('handleSubmitSubGroupParticipants');
		this._isSpinner = true;
		var tempUniquekey1 = event.currentTarget.dataset.id;		//	subGroupId
		var tempSubGroupDetails = {};
		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== tempUniquekey1) {
				continue;
			}
			tempSubGroupDetails = this._subGroupList[i];
		}

		clickSubmitSubGroupParticipants({params: {
			subGroupDetails: JSON.stringify(tempSubGroupDetails)
			}}).then(result=>{
				console.log('handleSubmitSubGroupParticipants result: ', result);

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					this.showErrorToast(result.message);
				}
				this.connectedCallback();
			})
			.catch(error=>{
				console.log('GroupDetails component');
				console.log('handleSubmitSubGroupParticipants Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}


	handleClickOnRequestTransfer(event) {
		console.log('handleClickOnRequestTransfer');
		this.dispatchEvent(new CustomEvent('disableshowparentbuttons'));
		var tempUniquekey1 = event.currentTarget.dataset.id;		//	subGroupId
		var tempUniquekey2 = event.currentTarget.dataset.index;		//	index in list (0...)	// index of participant in list
		this._displayTransferContainer = true;

		this._tempParticipant = {};
		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== tempUniquekey1) {
				continue;
			}
			this._tempParticipant = this._subGroupList[i].subGroupParticipantList[tempUniquekey2];
		}

		this._requestedContactId = this._tempParticipant.oldContactId;
		this._requestedContactEmail = this._tempParticipant.oldContactEmail;
		this._requestedContactName = this._tempParticipant.oldContactName;

		this._displayTransferFinalNextButton = false;
		this._displayFinalCancel = false;
	}

	handleCRChangeNewContactEmail(event) {
		console.log('handleCRChangeNewContactEmail');
		var newContactDetails = event.detail.recorddetails ? JSON.parse(event.detail.recorddetails) : null;
		this._requestedContactId = newContactDetails ? newContactDetails.id : '';
		this._requestedContactEmail = newContactDetails ? newContactDetails.enteredText !== null ? newContactDetails.enteredText : '' : '';
		this._requestedContactName = newContactDetails ? newContactDetails.field2val : '';
		this._displayTransferFinalNextButton = (this._requestedContactEmail != '' && this._tempParticipant.oldContactEmail !== this._requestedContactEmail);
		if (this._requestedContactEmail !== undefined ) {
			if (!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this._requestedContactEmail))) this._displayTransferFinalNextButton = false;
		}
	}

	handleTransferFinalNextClick() {
		console.log('handleTransferFinalNextClick');
		this.dispatchEvent(new CustomEvent('enableshowparentbuttons'));

		var newTransferDetails = {};
		newTransferDetails.crContactId = this._requestedContactId;
		newTransferDetails.crContactEmail = this._requestedContactEmail;
		newTransferDetails.crContactName = this._requestedContactName;
		this._tempParticipant.isNewTransferExist = true;
		this._tempParticipant.newTransferDetails = newTransferDetails;

		this._tempParticipant.newContactId = newTransferDetails.crContactId;
		this._tempParticipant.newContactEmail = newTransferDetails.crContactEmail;
		this._tempParticipant.newContactName = newTransferDetails.crContactName;

		this.addEmailToDisabledEmails(newTransferDetails.crContactEmail);
		this._displayFinalSubmitTransferButton = true;

		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== this._tempParticipant.uniquekey1) {
				continue;
			}
			var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));
			tempSubGroupList[i].subGroupParticipantList[this._tempParticipant.uniquekey2] = this._tempParticipant;
			this._subGroupList = tempSubGroupList;
			this._requestedContactId = '';
			this._requestedContactEmail = '';
			this._requestedContactName = '';
			this._displayTransferContainer = false;
		}
		this._displayFinalCancel = true;
	}

	addEmailToDisabledEmails(emailString) {
		this._disabledEmails.push(emailString);
		this._disabledEmailsString = JSON.stringify(this._disabledEmails);
	}

	removeEmailFromDisabledEmails(emailString) {
		var tempDisabledEmails = [];
		for (var i = 0; i < this._disabledEmails.length; i++) {
			if (this._disabledEmails[i] !== emailString) {
				tempDisabledEmails.push(this._disabledEmails[i]);
			}
		}
		this._disabledEmails = tempDisabledEmails;
		this._disabledEmailsString = JSON.stringify(this._disabledEmails);
	}

	handleClickOnNewRequestEdit(event) {
		console.log('handleClickOnNewRequestEdit');
		var tempUniquekey1 = event.currentTarget.dataset.id;		//	subGroupId
		var tempUniquekey2 = event.currentTarget.dataset.index;		//	index in list (0...)	// index of participant in list
		this._displayTransferContainer = true;

		this._tempParticipant = {};
		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== tempUniquekey1) {
				continue;
			}
			this._tempParticipant = this._subGroupList[i].subGroupParticipantList[tempUniquekey2];
		}

		this._requestedContactId = this._tempParticipant.newTransferDetails.crContactId;
		this._requestedContactEmail = this._tempParticipant.newTransferDetails.crContactEmail;
		this._requestedContactName = this._tempParticipant.newTransferDetails.crContactName;
		this._displayTransferFinalNextButton = true;
		this._displayFinalCancel = false;
		console.log('this._tempParticipant: ', this._tempParticipant);

	}

	handleClickOnNewRequestDelete(event) {
		var tempUniquekey1 = event.currentTarget.dataset.id;		//	subGroupId
		var tempUniquekey2 = event.currentTarget.dataset.index;		//	index in list (0...)	// index of participant in list

		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== tempUniquekey1) {
				continue;
			}
			var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));
			this.removeEmailFromDisabledEmails(tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].newTransferDetails.crContactEmail);

			tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].isNewTransferExist = false;
			tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].newTransferDetails = {};

			tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].newContactId = tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].oldContactId;
			tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].newContactEmail = tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].oldContactEmail;
			tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].newContactName = tempSubGroupList[i].subGroupParticipantList[tempUniquekey2].oldContactName;
			this._subGroupList = tempSubGroupList;

			this._displayFinalSubmitTransferButton = false;
			for (var i = 0; i < this._subGroupList.length; i++) {
				for (var i2 = 0; i2 < this._subGroupList[i].subGroupParticipantList.length; i2++) {
					console.log('000 isNewTransferExist: ', this._subGroupList[i].subGroupParticipantList[i2].isNewTransferExist);
					if (this._subGroupList[i].subGroupParticipantList[i2].isNewTransferExist == true) this._displayFinalSubmitTransferButton = true;
				}
			}
		}

	}

	handleTransferFinalCancelClick() {
		console.log('handleTransferFinalCancelClick');
		// this.dispatchEvent(new CustomEvent('enableshowparentbuttons'));
		// this.connectedCallback();
		this._requestedContactId = '';
		this._requestedContactEmail = '';
		this._requestedContactName = '';
		this._displayTransferContainer = false;
		this._displayFinalCancel = true;
		// this._displayChangeRequestCancelButton = true;
	}

	handleFinalSubmitTransferClick() {
		console.log('handleFinalSubmitTransferClick this._subGroupList: ', this._subGroupList);
		this.dispatchEvent(new CustomEvent('finalsubmitgrouptransfer', { bubbles: true, detail: { eventparams: JSON.stringify(this._subGroupList) } }));
		this._requestedContactId = '';
		this._requestedContactEmail = '';
		this._requestedContactName = '';
		this._displayTransferContainer = false;
	}

	handleFinalCancel() {
		this.dispatchEvent(new CustomEvent('gdcomponentterminate'));
		this._displayTransferContainer = false;
	}


	//	Submit	// Registration Flow
	handleClickSubmitRegistrationFlow() {
		console.log('handleClickSubmitRegistrationFlow');

		clickSubmitRegistrationFlow({params: {
			// groupDetails: JSON.stringify(this.recordId),
			subGroupList: JSON.stringify(this._subGroupList),
			isGroupDefinitionMode: this._displayGroupDefinition
			}}).then(result=>{
				console.log('handleClickSubmitRegistrationFlow result: ', result);
				console.log('handleClickSubmitRegistrationFlow result.participantsString: ', result.participantsString);

				this.dispatchEvent(new CustomEvent('submitclick', { bubbles: true, detail: { participantsstring: result.participantsString} }));
			})
			.catch(error=>{
				console.log('GroupDetails component');
				console.log('clickSubmitRegistrationFlow Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	handleAddMoreTicketsClick() {
		var newURL = window.location.protocol + "//" + window.location.host + "/s/event-registration" + "?ei=" + this._eventId + "&gi=" + this._groupId;
		window.location.replace(newURL);
	}

	handleAccordionArrowClick(event) {
		var accordionIndex = event.currentTarget.dataset.id;
		var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));
		tempSubGroupList[accordionIndex].accordionIsExpanded = !tempSubGroupList[accordionIndex].accordionIsExpanded;
		this._subGroupList = tempSubGroupList;

	}

	showSuccessToast(msg) {
		const evt = new ShowToastEvent({
			title: 'Success',
			message: msg,
			variant: 'success',
			mode: 'dismissable'
		});
		this.dispatchEvent(evt);
	}

	showErrorToast(msg) {
		const evt = new ShowToastEvent({
			title: 'Error',
			message: msg,
			variant: 'error',
			mode: 'dismissable'
		});
		this.dispatchEvent(evt);
	}

}