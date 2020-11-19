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
		console.log('handleOngroupchangecontactemail this._disabledEmails: ', this._disabledEmails);
		console.log('handleOngroupchangecontactemail this._disabledEmailsNotThisGroup: ', this._disabledEmailsNotThisGroup);
		console.log('handleOngroupchangecontactemail this._disabledEmailsThisGroup: ', this._disabledEmailsThisGroup);

		const subGroupId = event.detail.uniquekey1;
		const participantIndex = event.detail.uniquekey2;
		const eventType = event.detail.eventtype;

		var participantDetails = event.detail.recorddetails ? JSON.parse(event.detail.recorddetails) : null;

		// console.log('participantDetails: ', participantDetails);
		console.log('participantDetails.originalText: ', participantDetails.originalText);
		console.log('participantDetails.enteredText: ', participantDetails.enteredText);
		// console.log('subGroupId: ', subGroupId);
		// console.log('participantIndex: ', participantIndex);
		console.log('eventType: ', eventType);

		// console.log('TEST1');

		// if (participantDetails.originalText == participantDetails.enteredText) return;

		// eventType === 'onblur' && 
		// console.log('TEST2');
		//	NOT VALID EMAIL
		// if ((!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(participantDetails.enteredText)) || participantDetails.enteredText === '')) {
		// 	console.log('NOT VALID EMAIL');
		// }
		//	ironman@hotmail.com
		// console.log('----------------------------');
		// console.log('participantDetails.enteredText: ', participantDetails.enteredText);
		// console.log('--');
		// console.log('this._disabledEmailsThisGroup: ', this._disabledEmailsThisGroup);
		// console.log('--');
		// console.log('this._disabledEmails: ', this._disabledEmails);
		// console.log('----------------------------');

		// if(this._disabledEmailsThisGroup.includes(participantDetails.enteredText)) {
		// 	console.log('includes in this._disabledEmailsThisGroup');
		// }
		// if(this._disabledEmails.includes(participantDetails.enteredText)) {
		// 	console.log('includes in this._disabledEmails');
		// }
		// console.log('TEST3');

		for (var i = 0; i < this._subGroupList.length; i++) {
			if (this._subGroupList[i].subGroupId !== subGroupId) {
				continue;
			}

			var tempSubGroupList = JSON.parse(JSON.stringify(this._subGroupList));

			// console.log('tempSubGroupList: ', tempSubGroupList);

			console.log('ZALUPA 0 INDEX: ', i);
			var currentParticipant = tempSubGroupList[i].subGroupParticipantList[participantIndex];

			//	Email is Empty
			if (participantDetails.enteredText === '') {

				console.log('VALIDATION: EMAIL IS EMPTY');

				if (participantDetails.originalText != '') this.removeEmailFromDisabledEmails(participantDetails.originalText);
				// console.log('ZALUPA 1 currentParticipant.errorInitial: ', currentParticipant.errorInitial);
				currentParticipant.buttonsSettings.displaySaveDraftButton = false;
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;
				currentParticipant.error = JSON.parse(JSON.stringify(currentParticipant.errorInitial));

				//	Order is Paid, when we show error message
				if (currentParticipant.buttonsSettings.enableAddInviteButtons) currentParticipant.error.hasError = true;

			//	Not valid EMAIL
			} else if ((!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(participantDetails.enteredText)) && eventType === 'onblur')) {

				console.log('VALIDATION: EMAIL IS INVALID');

				currentParticipant.error.hasError = true;
				currentParticipant.error.message = 'Not valid email';
				currentParticipant.buttonsSettings.displaySaveDraftButton = false;
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;

			//	Value is not Changed
			} else if (participantDetails.originalText == participantDetails.enteredText) {

				console.log('VALIDATION: VALUE IS NOT CHANGED');

				return;

			//	In all next conditions EMAIL will be valid
			} else if (!(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(participantDetails.enteredText))) {
				console.log('NOT VALID EMAIL');
				return;

			//	alex1983_work@tut.by
			//	Already Registered On Event as Solo or in other Group
			} else if (this._disabledEmailsNotThisGroup.includes(participantDetails.enteredText)) {
			// } else if (!this._disabledEmailsThisGroup.includes(participantDetails.enteredText) && this._disabledEmailsNotThisGroup.includes(participantDetails.enteredText)) {
				console.log('VALIDATION: ALREADY REGISTERED');

				// if (participantDetails.originalText != '' && currentParticipant.error.message === 'Duplicate email') this.removeEmailFromDisabledEmails(participantDetails.originalText);
				if (participantDetails.originalText != '') this.removeEmailFromDisabledEmails(participantDetails.originalText);

				currentParticipant.error.hasError = true;
				currentParticipant.error.message = 'Already registered on this event';
				currentParticipant.buttonsSettings.displaySaveDraftButton = false;
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;
				console.log('ZALUPA 31');

			//	Email was changed several times and at last user entered First Initial Email
			} else if (currentParticipant.oldContactEmail === participantDetails.enteredText) {

				console.log('VALIDATION: ORIGINAL IS ENTERED');

				currentParticipant.error = JSON.parse(JSON.stringify(currentParticipant.errorInitial));
				currentParticipant.buttonsSettings = JSON.parse(JSON.stringify(currentParticipant.buttonsSettingsInitial));

			//	Email was already entered in THIS group
			} else if (this._disabledEmailsThisGroup.includes(participantDetails.enteredText)) {

				console.log('VALIDATION: DUPLICATE EMAIL');

				if (participantDetails.originalText != '' && currentParticipant.error.message !== 'Duplicate email') this.removeEmailFromDisabledEmails(participantDetails.originalText);
				console.log('ZALUPA 4');
				currentParticipant.error.hasError = true;
				currentParticipant.error.message = 'Duplicate email';
				currentParticipant.buttonsSettings.displaySaveDraftButton = false;
				currentParticipant.buttonsSettings.displayAddButton = false;
				currentParticipant.buttonsSettings.displayInviteButton = false;
				currentParticipant.buttonsSettings.isInvited = false;
				currentParticipant.buttonsSettings.isConfirmed = false;
				// if (participantDetails.enteredText != '') this.addEmailToDisabledEmails(participantDetails.enteredText);
				console.log('ZALUPA 41');


			//	Allow changes
			} else {
				console.log('VALIDATION: ALLOW CHANGES');

				if (participantDetails.originalText != '' && currentParticipant.error.message !== 'Duplicate email') this.removeEmailFromDisabledEmails(participantDetails.originalText);
				if (participantDetails.enteredText != '') this.addEmailToDisabledEmails(participantDetails.enteredText);

				currentParticipant.error.hasError = false;
				currentParticipant.error.message = '';

				//	Order is Paid
				if (currentParticipant.buttonsSettings.enableAddInviteButtons) {
					currentParticipant.buttonsSettings.displaySaveDraftButton = true;
					if (participantDetails.id) {
						currentParticipant.buttonsSettings.displayAddButton = true;
					} else {
						currentParticipant.buttonsSettings.displayInviteButton = true;
					}
				
				//	Order is not Paid (so we can't send any emails to the Participant)
				} else {
					currentParticipant.buttonsSettings.displaySaveDraftButton = true;
				}


				currentParticipant.newContactId = participantDetails ? participantDetails.id : null;
				currentParticipant.newContactEmail = participantDetails ? participantDetails.enteredText : null;
				currentParticipant.newContactName = participantDetails ? participantDetails.field2val : null;

			}
			// if (participantDetails.originalText != '') this.removeEmailFromDisabledEmails(participantDetails.originalText);
			console.log('ZALUPA 200__00 currentParticipant: ', currentParticipant);
			// this.removeEmailFromDisabledEmails(participantDetails.originalText);
			console.log('ZALUPA 200 currentParticipant: ', currentParticipant);
			tempSubGroupList[i].subGroupParticipantList[participantIndex] = currentParticipant;

			if (participantDetails.originalText == participantDetails.enteredText && eventType !== 'onblur') return;

			this._subGroupList = tempSubGroupList;
			console.log('ZALUPA 400');
			console.log('ZZZ3 this._disabledEmails: ', this._disabledEmails);
		}
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

				// if (this._disabledEmailsThisGroup[i] === emailString && !alreadyRemoved) {
				// 	continue;
				// }

				// if (this._disabledEmailsThisGroup[i] === emailString) alreadyRemoved = true;
				// tempDisabledEmailsGroup.push(this._disabledEmailsThisGroup[i]);

				// OLD LOGIC
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


}