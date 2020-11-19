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

	_invitedMessage = 'Successfully invited to the community and to the event';
	_confirmedMessage = 'Successfully registered for the event';

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

				this._disabledEmailsNotThisGroup = result.disabledEmailsNotThisGroup;
				this._disabledEmailsThisGroup = result.disabledEmailsThisGroup;
				this.combineDisabledEmails();

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
		console.log('----------------------------');
		// console.log('handleOngroupchangecontactemail this._disabledEmails: ', this._disabledEmails);
		// console.log('handleOngroupchangecontactemail this._disabledEmailsNotThisGroup: ', this._disabledEmailsNotThisGroup);
		// console.log('handleOngroupchangecontactemail this._disabledEmailsThisGroup: ', this._disabledEmailsThisGroup);

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
			if ((!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(participantDetails.enteredText)) && eventType === 'onblur')) {
				console.log('VALIDATION: EMAIL IS INVALID');

				currentParticipant.error.hasError = true;
				currentParticipant.error.message = 'Not valid email';
				currentParticipant.buttonsSettings.displaySaveDraftButton = false;

				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;

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
			if (currentParticipant.buttonsSettings.enableAddInviteButtons) {
				currentParticipant.buttonsSettings.displaySaveDraftButton = true;
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				if (participantDetails.id) {
					currentParticipant.buttonsSettings.displayAddButton = true;
				} else {
					currentParticipant.buttonsSettings.displayInviteButton = true;
				}
			
			//	Order is not Paid (so we can't send any emails to the Participant)
			} else {
				currentParticipant.buttonsSettings.displaySaveDraftButton = true;
			}

			tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;

			// if (participantDetails.originalText == participantDetails.enteredText && eventType !== 'onblur') return;

			this._subGroupList = tempSubGroupList;

			this.processDuplicateParticipants();
		}

	}

	processDuplicateParticipants() {
		console.log('processDuplicateParticipants START this._subGroupList: ', this._subGroupList);
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

				console.log('' + contactEmail + ' = ', emailInMap);
				// emailToIsDuplicate[contactEmail] = emailInMap;

				if (emailInMap) {
					emailToIsDuplicate[contactEmail] = true;
				} else {
					emailToIsDuplicate[contactEmail] = false;
				}
			}
		}

		console.log('emailToIsDuplicate: ', emailToIsDuplicate);

		for (var i = 0; i < tempSubGroupList.length; i++) {
			for (var i2 = 0; i2 < tempSubGroupList[i].subGroupParticipantList.length; i2++) {
				if (!tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail) continue;

				let contactEmail = tempSubGroupList[i].subGroupParticipantList[i2].newContactEmail;

				let hasDuplicates = emailToIsDuplicate[contactEmail];

				if (!hasDuplicates) {
					let currentErrorMessage = tempSubGroupList[i].subGroupParticipantList[i2].error.message;

					if (currentErrorMessage === 'Duplicate email') {
						let buttonsSettingsTemp = JSON.parse(JSON.stringify(tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettingsIntermediate));
						tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings = buttonsSettingsTemp;
						tempSubGroupList[i].subGroupParticipantList[i2].error.hasError = false;
						tempSubGroupList[i].subGroupParticipantList[i2].error.message = '';
					}

					let buttonsSettingsTemp = JSON.parse(JSON.stringify(tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings));
					tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettingsIntermediate = buttonsSettingsTemp;

				} else {
					console.log('1 DUPLICATE FOUND i: ', i);
					console.log('2 DUPLICATE FOUND i2: ', i2);
					let currentErrorMessage = tempSubGroupList[i].subGroupParticipantList[i2].error.message;

					if (currentErrorMessage === 'Duplicate email') {
						continue;
					}

					if (currentErrorMessage !== 'Already registered on this event') {

						//	NEW DUPLICATE FOUND
						tempSubGroupList[i].subGroupParticipantList[i2].error.hasError = true;
						tempSubGroupList[i].subGroupParticipantList[i2].error.message = 'Duplicate email';
						tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displaySaveDraftButton = false;
						tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displayAddButton = false;
						tempSubGroupList[i].subGroupParticipantList[i2].buttonsSettings.displayInviteButton = false;
					}
				}
			}
		}

		this._subGroupList = tempSubGroupList;
		this._disabledEmailsThisGroup = tempDisabledEmailsGroup;
		this.combineDisabledEmails();
		console.log('processDuplicateParticipants END this._subGroupList: ', this._subGroupList);
	}


	addEmailToDisabledEmails(emailString) {
		this._disabledEmailsThisGroup.push(emailString);
		// this.combineDisabledEmails();
	}

	removeEmailFromDisabledEmails(emailString) {
		console.log('removeEmailFromDisabledEmails START');
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
		console.log('removeEmailFromDisabledEmails END');
		this.combineDisabledEmails();
	}

	combineDisabledEmails() {
		console.log('combineDisabledEmails START');
		// console.log('combineDisabledEmails this._disabledEmailsNotThisGroup: ', this._disabledEmailsNotThisGroup);
		// console.log('combineDisabledEmails this._disabledEmailsThisGroup: ', this._disabledEmailsThisGroup);
		var tempDisabledEmails = [];
		// tempDisabledEmails.push.apply(this._disabledEmailsNotThisGroup, this._disabledEmailsThisGroup);

		tempDisabledEmails.push(...this._disabledEmailsNotThisGroup);
		tempDisabledEmails.push(...this._disabledEmailsThisGroup);

		this._disabledEmailsString = JSON.stringify(tempDisabledEmails);
		this._disabledEmails = JSON.parse(this._disabledEmailsString);

		// console.log('ZZZ1 tempDisabledEmails: ', tempDisabledEmails);
		// console.log('ZZZ2 this._disabledEmailsString: ', this._disabledEmailsString);
		// console.log('ZZZ3 this._disabledEmails: ', this._disabledEmails);
		console.log('combineDisabledEmails END');
	}

	//	contact already exist at the community
	handleAddClick() {
		console.log('handleAddClick');
	}

	//	contact not exist at the community
	handleInviteClick() {
		console.log('handleAddClick');
	}

	//	save as draft (can be changed in future)
	handleSaveClick() {
		console.log('handleAddClick');
	}


}