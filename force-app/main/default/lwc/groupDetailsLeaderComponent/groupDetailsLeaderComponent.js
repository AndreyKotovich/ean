import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGroupDetails from '@salesforce/apex/GroupDetailsLeaderController.getGroupDetails'
import addButtonClick from '@salesforce/apex/GroupDetailsLeaderController.addButtonClick'
import inviteButtonClick from '@salesforce/apex/GroupDetailsLeaderController.inviteButtonClick'
import saveButtonClick from '@salesforce/apex/GroupDetailsLeaderController.saveButtonClick'
import groupNameSave from '@salesforce/apex/GroupDetailsLeaderController.groupNameSave'

export default class GroupDetailsLeaderComponent extends LightningElement {
	@api recordId;				// required

	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_isSpinner = true;
	_isError = false;

	_invitedMessage = 'Successfully invited to the community and to the event';
	_confirmedMessage = 'Successfully registered for the event';
	_warningMessage = 'Will be automatically registered for the event after payment';

	_groupId = '';
	_eventId = '';
	_groupName = '';
	_groupNameInitial = '';
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
	_disabledEmailsString;
	_disabledEmailsThisGroup;
	_disabledEmailsNotThisGroup;

	_groupNameReservedMessage = 'Already reserved';
	_groupEmptyMessage = 'Enter Group Name';
	_isGroupNameReserved;
	_isGroupNameEmpty;

	_disabledGroupNames;
	_displayGroupNameButtons;

	connectedCallback() {
		this._isSpinner = true;

		getGroupDetails({params: {
			groupId: this.recordId
			}}).then(result=>{
				// console.log('result: ', result);
				this._isSpinner = false;

				if (!result.result) {
					console.log('result: ', result);
					this._isError = true;
					return;
				}

				this._isError = false;

				this._disabledEmailsNotThisGroup = result.disabledEmailsNotThisGroup;
				this._disabledEmailsThisGroup = result.disabledEmailsThisGroup;
				this.combineDisabledEmails();
				this._disabledGroupNames = result.disabledGroupNames;

				this._groupId = result.groupDetails.groupId;
				this._groupName = result.groupDetails.groupName;
				this._groupNameInitial = result.groupDetails.groupNameInitial;
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
				this._isGroupNameReserved = false;
				this._isGroupNameEmpty = false;
				this._displayGroupNameButtons = false;

				this.processDuplicateParticipants();
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
		const subGroupId = event.detail.uniquekey1;
		const participantIndex = event.detail.uniquekey2;
		const eventType = event.detail.eventtype;
		var participantDetails = event.detail.recorddetails ? JSON.parse(event.detail.recorddetails) : null;

		for (var i = 0; i < this._subGroupList.length; i++) {

			if (this._subGroupList[i].subGroupId !== subGroupId) {
				continue;
			}

			var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));
			var currentParticipant = tempSubGroupList[i].subGroupParticipantList[participantIndex];

			currentParticipant.newContactId = participantDetails ? participantDetails.id : null;
			currentParticipant.newContactEmail = participantDetails ? participantDetails.enteredText : null;
			currentParticipant.newContactName = participantDetails ? participantDetails.field2val : null;
			console.log();

			//	VALIDATION 1	ENTERED EMAIL IS EMPTY
			if (participantDetails.enteredText === '') {
				console.log('VALIDATION: EMAIL IS EMPTY');

				currentParticipant.buttonsSettings.displaySaveDraftButton = false;
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;
				currentParticipant.buttonsSettings.displayWarningMessage = false;
				currentParticipant.error = JSON.parse(JSON.stringify(currentParticipant.errorInitial));

				if (currentParticipant.oldContactEmail !== '') currentParticipant.buttonsSettings.displaySaveDraftButton = true;

				//	Order is Paid, when we show error message
				if (currentParticipant.buttonsSettings.enableAddInviteButtons) currentParticipant.error.hasError = true;
				tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;
				this._subGroupList = tempSubGroupList;

				this.processDuplicateParticipants();
				return;
			}

			//	VALIDATION 2	INVALID EMAIL IS ENTERED
			if (!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(participantDetails.enteredText))) {
			// if ((!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(participantDetails.enteredText)) && eventType === 'onblur')) {
				console.log('VALIDATION: EMAIL IS INVALID');

				currentParticipant.error.hasError = true;
				currentParticipant.error.message = 'Not valid email';
				currentParticipant.buttonsSettings.displaySaveDraftButton = false;

				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;
				currentParticipant.buttonsSettings.displayWarningMessage = false;

				tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;
				this._subGroupList = tempSubGroupList;

				this.processDuplicateParticipants();
				return;
			}

			//	VALIDATION 3	EMAIL IS NOT CHANGED
			if (participantDetails.originalText == participantDetails.enteredText) {
				console.log('VALIDATION: VALUE IS NOT CHANGED');
				return;
			}

			//	VALIDATION 4	ALREADY REGISTERED AS SOLO OR IN OTHER GROUP
			if (this._disabledEmailsNotThisGroup.includes(participantDetails.enteredText)) {
				console.log('VALIDATION: ALREADY REGISTERED');

				currentParticipant.error.hasError = true;
				currentParticipant.error.message = 'Already registered on this event';
				currentParticipant.buttonsSettings.displaySaveDraftButton = false;
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;
				currentParticipant.buttonsSettings.displayWarningMessage = false;
	
				tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;
				this._subGroupList = tempSubGroupList;

				this.processDuplicateParticipants();
				return;
			}

			//	VALIDATION 5	ORIGINAL EMAIL IS ENTERED
			if (currentParticipant.oldContactEmail === participantDetails.enteredText) {
				console.log('VALIDATION: ORIGINAL IS ENTERED');

				currentParticipant.error = JSON.parse(JSON.stringify(currentParticipant.errorInitial));
				currentParticipant.buttonsSettings = JSON.parse(JSON.stringify(currentParticipant.buttonsSettingsInitial));

				tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;
				this._subGroupList = tempSubGroupList;

				this.processDuplicateParticipants();
				return;
			}

			//	VALIDATION 6	 DUPLICATE EMAIL IN THIS GROUP
			if (this._disabledEmailsThisGroup.includes(participantDetails.enteredText)) {
				console.log('VALIDATION: DUPLICATE EMAIL');

				currentParticipant.buttonsSettings.displayWarningMessage = false;
				tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;
				this._subGroupList = tempSubGroupList;
				this.processDuplicateParticipants();
				return;
			}

			//	VALIDATION IS PASSED
			console.log('VALIDATION: IS PASSED');

			currentParticipant.error.hasError = false;
			currentParticipant.error.message = '';

			//	Order is Paid
			currentParticipant.buttonsSettings.displaySaveDraftButton = true;
			if (currentParticipant.buttonsSettings.enableAddInviteButtons) {
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				if (participantDetails.id) {
					currentParticipant.buttonsSettings.displayAddButton = true;
				} else {
					currentParticipant.buttonsSettings.displayInviteButton = true;
				}
			}

			if (currentParticipant.buttonsSettings.enableWarningMessage) {
				if (participantDetails.id) {
					currentParticipant.buttonsSettings.displayWarningMessage = true;
				} else {
					currentParticipant.buttonsSettings.displayWarningMessage = false;
				}
			}

			tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;

			// if (participantDetails.originalText == participantDetails.enteredText && eventType !== 'onblur') return;

			this._subGroupList = tempSubGroupList;

			this.processDuplicateParticipants();
		}

	}

	processDuplicateParticipants() {
		var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));

		var emailToIsDuplicate = {};
		var tempDisabledEmailsGroup = [];
		for (var i = 0; i < tempSubGroupList.length; i++) {
			for (var i2 = 0; i2 < tempSubGroupList[i].subGroupParticipantList.length; i2++) {
				// if (tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail == undefined || tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail == '') continue;
				if (!tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail) continue;

				let contactEmail = tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail;
				tempDisabledEmailsGroup.push(contactEmail);

				let emailInMap = emailToIsDuplicate.hasOwnProperty(contactEmail);

				if (emailInMap) {
					emailToIsDuplicate[contactEmail] = true;
				} else {
					emailToIsDuplicate[contactEmail] = false;
				}
			}
		}


		for (var i = 0; i < tempSubGroupList.length; i++) {
			for (var i2 = 0; i2 < tempSubGroupList[i].subGroupParticipantList.length; i2++) {
				if (!tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail) continue;

				let contactEmail = tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail;

				let hasDuplicates = emailToIsDuplicate[contactEmail];

				if (!hasDuplicates) {

					//	NO DUPLICATE
					let currentErrorMessage = tempSubGroupList[i].subGroupParticipantList[i2].error.message;

					if (currentErrorMessage === 'Duplicate email') {
						let buttonsSettingsTemp = JSON.parse(JSON.stringify(tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettingsIntermediate));
						tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings = buttonsSettingsTemp;
						tempSubGroupList[i].subGroupParticipantList[i2].error.hasError = false;
						tempSubGroupList[i].subGroupParticipantList[i2].error.message = '';

						// //	display buttons
						// if (tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail !== '')
						// 	tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displaySaveDraftButton = true;

						// 	//	Order is Paid
						// 	if (tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.enableAddInviteButtons) {
						// 		tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displayAddButton = false;
						// 		tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displayInviteButton = false;
						// 		if (tempSubGroupList[i].subGroupParticipantList[i2].newContactId) {
						// 			tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displayAddButton = true;
						// 		} else {
						// 			tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displayInviteButton = true;
						// 		}
						// 	}
					}

					let buttonsSettingsTemp = JSON.parse(JSON.stringify(tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings));
					tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettingsIntermediate = buttonsSettingsTemp;

				} else {
					let currentErrorMessage = tempSubGroupList[i].subGroupParticipantList[i2].error.message;

					if (currentErrorMessage === 'Duplicate email') {
						continue;
					}

					// if (currentErrorMessage !== 'Already registered on this event') {

						//	NEW DUPLICATE FOUND
						tempSubGroupList[i].subGroupParticipantList[i2].error.hasError = true;
						tempSubGroupList[i].subGroupParticipantList[i2].error.message = 'Duplicate email';
						tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displaySaveDraftButton = false;
						tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displayAddButton = false;
						tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displayInviteButton = false;
					// }
				}
			}
		}

		this._subGroupList = tempSubGroupList;
		this._disabledEmailsThisGroup = tempDisabledEmailsGroup;
		this.combineDisabledEmails();
	}


	addEmailToDisabledEmails(emailString) {
		this._disabledEmailsThisGroup.push(emailString);
		// this.combineDisabledEmails();
	}

	removeEmailFromDisabledEmails(emailString) {
		// if (emailString != '') {
			var tempDisabledEmailsGroup = [];
			// var alreadyRemoved = false;
			for (var i = 0; i < this._disabledEmailsThisGroup.length; i++) {

				if (this._disabledEmailsThisGroup[i] !== emailString) {
					tempDisabledEmailsGroup.push(this._disabledEmailsThisGroup[i]);
				}
			}
			this._disabledEmailsThisGroup = tempDisabledEmailsGroup;
		// }
		this.combineDisabledEmails();
	}

	combineDisabledEmails() {
		var tempDisabledEmails = [];
		tempDisabledEmails.push(...this._disabledEmailsNotThisGroup);
		tempDisabledEmails.push(...this._disabledEmailsThisGroup);

		this._disabledEmailsString = JSON.stringify(tempDisabledEmails);
		this._disabledEmails = JSON.parse(this._disabledEmailsString);
	}

	//	contact already exist at the community
	handleAddClick(event) {
		var subGroupIndex = event.currentTarget.dataset.id;
		var participantIndex = event.currentTarget.dataset.index;
		var subGroupId = this._subGroupList[subGroupIndex].subGroupId;
		var currentParticipant = JSON.parse(JSON.stringify(this._subGroupList[subGroupIndex].subGroupParticipantList[participantIndex]));

		this._isSpinner = true;
		console.log('handleAddClick currentParticipant: ', currentParticipant);

		addButtonClick({params: {
			subGroupId: subGroupId,
			participantDetailsString: JSON.stringify(currentParticipant)
			}}).then(result=>{

				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					console.log('handleAddClick result: ', result);
					this.showErrorToast(result.message);
					return;
				}

				var buttonsSettings = JSON.parse(JSON.stringify(currentParticipant.buttonsSettings));
				buttonsSettings.enableAddInviteButtons = false;
				buttonsSettings.displayAddButton = false;
				buttonsSettings.displayInviteButton = false;
				buttonsSettings.displaySaveDraftButton = false;
				// buttonsSettings.isDraftStatus = false;
				buttonsSettings.isInvited = false;
				buttonsSettings.isConfirmed = true;
				currentParticipant.buttonsSettings = buttonsSettings;
				currentParticipant.buttonsSettingsInitial = buttonsSettings;
				currentParticipant.buttonsSettingsIntermediate = buttonsSettings;

				var error = JSON.parse(JSON.stringify(currentParticipant.error));
				error.hasError = false;
				error.message = '';
				currentParticipant.error = error;
				currentParticipant.errorInitial = error;

				if (!currentParticipant.oldContactEmail && currentParticipant.newContactEmail) this._totalGroupExistingParticipants++;

				currentParticipant.oldContactId = '' + currentParticipant.newContactId;
				currentParticipant.oldContactName = '' + currentParticipant.newContactName;
				currentParticipant.oldContactEmail = '' + currentParticipant.newContactEmail;

				currentParticipant.disabledToEdit = true;
				currentParticipant.invitationStatusInGroup = 'Confirmed';

				this._subGroupList[subGroupIndex].subGroupParticipantList[participantIndex] = currentParticipant;
			})
			.catch(error=>{
				console.log('groupDetailsLeaderComponent error: ', error);
				console.log('handleAddClick Error: ' + JSON.stringify(error));
				this._isError = true;

			})

	}

	//	contact not exist at the community
	handleInviteClick(event) {
		var subGroupIndex = event.currentTarget.dataset.id;
		var participantIndex = event.currentTarget.dataset.index;
		var subGroupId = this._subGroupList[subGroupIndex].subGroupId;
		var currentParticipant = JSON.parse(JSON.stringify(this._subGroupList[subGroupIndex].subGroupParticipantList[participantIndex]));

		this._isSpinner = true;

		inviteButtonClick({params: {
			subGroupId: subGroupId,
			participantDetailsString: JSON.stringify(currentParticipant)
			}}).then(result=>{
				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					console.log('handleInviteClick result: ', result);
					this.showErrorToast(result.message);
					return;
				}
				// this.connectedCallback();

				var buttonsSettings = JSON.parse(JSON.stringify(currentParticipant.buttonsSettings));
				buttonsSettings.enableAddInviteButtons = false;
				buttonsSettings.displayAddButton = true;
				buttonsSettings.displayInviteButton = false;
				buttonsSettings.displaySaveDraftButton = false;
				// buttonsSettings.isDraftStatus = false;
				buttonsSettings.isInvited = true;
				buttonsSettings.isConfirmed = false;
				currentParticipant.buttonsSettings = buttonsSettings;
				currentParticipant.buttonsSettingsInitial = buttonsSettings;
				currentParticipant.buttonsSettingsIntermediate = buttonsSettings;

				var error = JSON.parse(JSON.stringify(currentParticipant.error));
				error.hasError = false;
				error.message = '';
				currentParticipant.error = error;
				currentParticipant.errorInitial = error;

				if (!currentParticipant.oldContactEmail && currentParticipant.newContactEmail) this._totalGroupExistingParticipants++;

				currentParticipant.oldContactId = '' + currentParticipant.newContactId;
				currentParticipant.oldContactName = '' + currentParticipant.newContactName;
				currentParticipant.oldContactEmail = '' + currentParticipant.newContactEmail;

				currentParticipant.disabledToEdit = true;
				currentParticipant.invitationStatusInGroup = 'Invited';

				this._subGroupList[subGroupIndex].subGroupParticipantList[participantIndex] = currentParticipant;
			})
			.catch(error=>{
				console.log('groupDetailsLeaderComponent error: ', error);
				console.log('inviteButtonClick Error: ' + JSON.stringify(error));
				this._isError = true;

			})

	}

	//	save as draft (can be changed in future)
	handleSaveClick(event) {
		var subGroupIndex = event.currentTarget.dataset.id;
		var participantIndex = event.currentTarget.dataset.index;
		var subGroupId = this._subGroupList[subGroupIndex].subGroupId;
		var currentParticipant = JSON.parse(JSON.stringify(this._subGroupList[subGroupIndex].subGroupParticipantList[participantIndex]));

		this._isSpinner = true;

		saveButtonClick({params: {
			subGroupId: subGroupId,
			participantDetailsString: JSON.stringify(currentParticipant)
			}}).then(result=>{
				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					console.log('handleSaveClick result: ', result);
					this.showErrorToast(result.message);
					return;
				}

				var buttonsSettings = JSON.parse(JSON.stringify(currentParticipant.buttonsSettings));
				if (buttonsSettings.enableAddInviteButtons) {	// order is paid
					if (currentParticipant.newContactId) buttonsSettings.displayAddButton = true;
					if (!currentParticipant.newContactId) buttonsSettings.displayInviteButton = true;
					if (!currentParticipant.newContactEmail) buttonsSettings.displayInviteButton = false;
				}

				if (buttonsSettings.enableWarningMessage) {
					if (currentParticipant.newContactId) buttonsSettings.displayWarningMessage = true;
					if (!currentParticipant.newContactId) buttonsSettings.displayWarningMessage = false;
				}

				// buttonsSettings.enableAddInviteButtons = true;	// order is paid

				buttonsSettings.displaySaveDraftButton = false;
				// buttonsSettings.isDraftStatus = true;
				buttonsSettings.isInvited = false;
				buttonsSettings.isConfirmed = false;
				currentParticipant.buttonsSettings = buttonsSettings;
				currentParticipant.buttonsSettingsInitial = buttonsSettings;
				currentParticipant.buttonsSettingsIntermediate = buttonsSettings;

				var error = JSON.parse(JSON.stringify(currentParticipant.error));
				error.hasError = false;
				error.message = '';
				currentParticipant.error = error;
				currentParticipant.errorInitial = error;

				if (!currentParticipant.oldContactEmail && currentParticipant.newContactEmail) this._totalGroupExistingParticipants++;
				if (currentParticipant.oldContactEmail && !currentParticipant.newContactEmail) this._totalGroupExistingParticipants--;

				currentParticipant.oldContactId = '' + currentParticipant.newContactId;
				currentParticipant.oldContactName = '' + currentParticipant.newContactName;
				currentParticipant.oldContactEmail = '' + currentParticipant.newContactEmail;

				currentParticipant.disabledToEdit = false;
				currentParticipant.invitationStatusInGroup = 'Draft';

				this._subGroupList[subGroupIndex].subGroupParticipantList[participantIndex] = currentParticipant;
			})
			.catch(error=>{
				console.log('groupDetailsLeaderComponent error: ', error);
				console.log('saveButtonClick Error: ' + JSON.stringify(error));
				this._isError = true;
			})
	}

	handleAddMoreTicketsClick() {
		var newURL = window.location.protocol + "//" + window.location.host + "/s/event-registration" + "?ei=" + this._eventId + "&gi=" + this._groupId;
		window.location.replace(newURL);
	}

	handleChangeGroupName(evt) {
		this._groupName = evt.target.value;

		if (!this._groupName) {
			this._displayGroupNameButtons = false;
			this._isGroupNameEmpty = true;
			this._isGroupNameReserved = false;
			return;
		}

		if (this._groupName === this._groupNameInitial) {
			this._displayGroupNameButtons = false;
			this._isGroupNameEmpty = false;
			this._isGroupNameReserved = false;
			return;
		}

		if (this._disabledGroupNames.includes(this._groupName)) {
			this._displayGroupNameButtons = false;
			this._isGroupNameEmpty = false;
			this._isGroupNameReserved = true;
			return;
		}

		this._displayGroupNameButtons = true;
	}

	handleGroupNameSave() {
		groupNameSave({params: {
			groupId: this._groupId,
			groupName: this._groupName,
			}}).then(result=>{
				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					console.log('handleGroupNameSave result: ', result);
					this.showErrorToast(result.message);
					return;
				}
				this._disabledGroupNames = result.disabledGroupNames;
				this._displayGroupNameButtons = false;
				this._isGroupNameEmpty = false;
				this._isGroupNameReserved = false;
				this._groupNameInitial = '' + this._groupName;
			})
			.catch(error=>{
				console.log('groupDetailsLeaderComponent error: ', error);
				console.log('handleGroupNameSave Error: ' + JSON.stringify(error));
				this._isError = true;
			})
	}

	handleGroupNameCancel() {
		this._groupName = '' + this._groupNameInitial;
		this._displayGroupNameButtons = false;
		this._isGroupNameEmpty = false;
		this._isGroupNameReserved = false;
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