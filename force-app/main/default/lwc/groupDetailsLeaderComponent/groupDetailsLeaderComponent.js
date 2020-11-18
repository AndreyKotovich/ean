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

		var participantDetails = event.detail.recorddetails ? JSON.parse(event.detail.recorddetails) : null;

		console.log('participantDetails: ', participantDetails);
		console.log('subGroupId: ', subGroupId);
		console.log('participantIndex: ', participantIndex);

	}

}