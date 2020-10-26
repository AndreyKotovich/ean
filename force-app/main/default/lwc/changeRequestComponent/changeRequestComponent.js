import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPreparedData from '@salesforce/apex/ChangeRequestController.getPreparedData';
import clickOnRevoke from '@salesforce/apex/ChangeRequestController.clickOnRevoke';
import submitSoloCancellation from '@salesforce/apex/ChangeRequestController.submitSoloCancellation';
import submitGroupCancellation from '@salesforce/apex/ChangeRequestController.submitGroupCancellation';
import submitSoloTransfer from '@salesforce/apex/ChangeRequestController.submitSoloTransfer';
import submitGroupTransfer from '@salesforce/apex/ChangeRequestController.finalSubmitTransferGroup';

export default class ChangeRequestComponent extends NavigationMixin(LightningElement) {
	@api recordId;				// required to work as EAN Staff (Customer Contact Record Id)

	_errorMessage = '';
	_noRecordsMessage = ''
	_newRequestMessageLabel = '';
	_isSpinner = true;
	_isError = false;

	_changeRequestsList;
	_componentLabel;

	_communityContactId;
	_communityContactName;
	_communityContactEmail;

	_displayNoRecordsMessage = false;
	_displayChangeRequestsPanel = false;
	_displayChangeRequestsList = false;
	_displayNewRequestDefinition = false;
	_displayTopButtons = false;
	_displayBottomButtons = false;
	_displayNewChangeRequestButton = false;
	_displayChangeRequestNextButton = false;
	_displayChangeRequestCancellButton = false;

	_displayMainPanel = true;
	_displayMyRegistrationsComponent = false;

	_displaySoloTransferContainer = false;
	_displayTransferFinalConfirmButton = false;
	_selectedSoloTransferParticipantId = '';
	_requestedContactId = '';
	_requestedContactEmail = '';
	_requestedContactName = '';
	_whereclause = '';

	_displayGroupTransferContainer = false;
	_selectedGroupIdForTransfer = '';
	
	
	_paramsString;

	_crTypes = [];
	_selectedCRType;
	_crDescription = '';

	initialSettings() {
		this._errorMessage = 'Something went wrong, please contact your system administrator.';
		this._noRecordsMessage = 'You have no Change Requests.'
		this._newRequestMessageLabel = 'Define A New Change Request';
		this._isSpinner = true;
		this._isError = false;
		this._displayNoRecordsMessage = false;
		this._displayChangeRequestsPanel = false;
		this._displayChangeRequestsList = false;
		this._displayNewRequestDefinition = false;
		this._displayTopButtons = false;
		this._displayBottomButtons = false;
		this._displayNewChangeRequestButton = false;
		this._displayChangeRequestNextButton = false;
		this._displayChangeRequestCancelButton = false;
		this._displayMainPanel = true;
		this._displayMyRegistrationsComponent = false;

		this._crTypes = [];
		this._selectedCRType;
		this._crDescription = '';

		this._displaySoloTransferContainer = false;
		this._requestedContactId = '';
		this._requestedContactEmail = '';
		this._requestedContactName = '';
		this._displayTransferFinalConfirmButton = false;

		this._displayGroupTransferContainer = false;
		this._selectedGroupIdForTransfer = '';
	}

	initialPositiveSettings() {
		console.log('initialPositiveSettings');
		this._displayNewChangeRequestButton = true;
		this._displayChangeRequestNextButton = false;
		this._displayChangeRequestCancelButton = false;
		this._displayChangeRequestsPanel = true;
		this._displayNewRequestDefinition = false;
		this._displayMyRegistrationsComponent = false;

		this._displayMainPanel = true;
		this._displayTransferFinalConfirmButton = false;
		this._displaySoloTransferContainer = false;
		this._selectedSoloTransferParticipantId = '';
		// this.connectedCallback();

		this._displayGroupTransferContainer = false;
		this._selectedGroupIdForTransfer = '';
	}

	connectedCallback() {
		this.initialSettings();
		console.log('ChangeRequestComponent connectedCallback');
		console.log('this.recordId: ', this.recordId);

		getPreparedData({settings: {
			recordId: this.recordId
			}}).then(result=>{
				console.log('result: ', result);
				// this._callbackResult = result;
				// this._callbackResultString = JSON.stringify(result);	// DELETE
				this._isSpinner = false;

				if (!result.result) {
					this._isError = true;
					return;
				}

				this._isError = false;
				this._communityContactId = result.communityContactId;
				this._communityContactName = result.communityContactName;
				this._communityContactEmail = result.communityContactEmail;
				// this._displayChangeRequestsPanel = true;
				this._changeRequestsList = result.changeRequestsList;
				this._displayNoRecordsMessage = result.displayNoRecordsMessage;
				this._displayChangeRequestsList = result.displayChangeRequestsList;
				this._componentLabel = result.componentLabel;

				this._displayTopButtons = true;
				this._displayBottomButtons = false;
				// this._displayTopButtons = result.displayTopButtons;
				// this._displayBottomButtons = result.displayBottomButtons;
				// this._displayNewChangeRequestButton = true;
				this.initialPositiveSettings();

				var requestsTypeListMap = result.requestsTypeListMap;
				this._selectedCRType = requestsTypeListMap[0].value
				for (var i = 0 ; i < requestsTypeListMap.length ; i++) {
					this._crTypes.push({label: requestsTypeListMap[i].label, value: requestsTypeListMap[i].value});
				}
			})
			.catch(error=>{
				console.log('ChangeRequestComponent');
				console.log('connectedCallbackGetGroupDetails Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	handleNewRequestClick() {
		console.log('handleNewRequestClick');
		this._displayNewChangeRequestButton = false;
		this._displayChangeRequestNextButton = true;
		this._displayChangeRequestCancelButton = true;
		this._displayChangeRequestsPanel = false;
		this._displayNewRequestDefinition = true;
	}

	//	'Solo Registration Cancellation'
	//	'Group Registration Cancellation'
	//	'Solo Registration Transfer'
	//	'Group Registration Transfer'
	handleNextClick() {
		console.log('handleNextClick this._selectedCRType: ', this._selectedCRType);
		this._displayNewChangeRequestButton = false;
		this._displayChangeRequestNextButton = false;
		this._displayChangeRequestCancelButton = true;

		let target = this.template.querySelector('[data-target-id="standardtextarea"]');
		this._crDescription = target.value;

		var params = {};
		params.selectedCRType = this._selectedCRType;
		params.contactRecordId = this.recordId;
		this._paramsString = JSON.stringify(params);

		var redirectToMyRegistrationsPage = ['Solo Registration Cancellation', 'Group Registration Cancellation', 'Solo Registration Transfer', 'Group Registration Transfer'];

		if (redirectToMyRegistrationsPage.includes(this._selectedCRType)) {
			this._displayMainPanel = false;
			this._displayMyRegistrationsComponent = true;
			// navigateCommunityPage(targetPageName, id);
		}
	}

	handleCancelClick() {
		console.log('handleCancelClick');
		this.initialPositiveSettings();
	}

	handleChangeCRType(event) {
		console.log('handleChangeCRType');
		this._selectedCRType = event.detail.value;
	}

	handleClickOnRevoke(event) {
		var сhangeRequestId = event.currentTarget.dataset.id;
		this._isSpinner = true;
		clickOnRevoke({params: {
			selectedChangeRequestId: сhangeRequestId
			}}).then(result=>{
				console.log('result: ', result);
				this._isError = false;
				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					this.showErrorToast(result.message);
				}

				this.connectedCallback();
			})
			.catch(error=>{
				console.log('ChangeRequestComponent');
				console.log('handleClickOnRevoke Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	//	SOLO CANCELLATION BLOCK
	handleSubmitSoloCancellation(event) {
		const selectedParticipantId = event.detail.selectedParticipantId;
		console.log('handleSubmitSoloCancellation selectedParticipantId: ', selectedParticipantId);

		this._isSpinner = true;
		submitSoloCancellation({params: {
			selectedContactId: this._communityContactId,
			crDescription: this._crDescription,
			selectedParticipantId: selectedParticipantId
			}}).then(result=>{
				console.log('result: ', result);
				this._isError = false;
				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					this.showErrorToast(result.message);
				}

				this.connectedCallback();
			})
			.catch(error=>{
				console.log('ChangeRequestComponent');
				console.log('submitSoloCancellation Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	//	SOLO TRANSFER BLOCK
	handleSubmitSoloTransfer(event) {
		this._selectedSoloTransferParticipantId = event.detail.selectedParticipantId;
		console.log('handleSubmitSoloTransfer this._selectedSoloTransferParticipantId: ', this._selectedSoloTransferParticipantId);

		// this._displayMainPanel = false;
		// this._displayMyRegistrationsComponent = false;
		this._displaySoloTransferContainer = true;
		this._displayChangeRequestCancelButton = false;
		this._displayTransferFinalConfirmButton = false;
		this._requestedContactId = '';
		this._requestedContactEmail = '';
		this._requestedContactName = '';
	}

	handleCRChangeNewContactEmail(event) {
		console.log('AAA handleCRChangeNewContactEmail');
		var newContactDetails = event.detail.recorddetails ? JSON.parse(event.detail.recorddetails) : null;
		this._requestedContactId = newContactDetails ? newContactDetails.id : '';
		this._requestedContactEmail = newContactDetails ? newContactDetails.enteredText !== null ? newContactDetails.enteredText : '' : '';
		this._requestedContactName = newContactDetails ? newContactDetails.field2val : '';
		this._displayTransferFinalConfirmButton = (this._requestedContactEmail != '' && this._communityContactEmail !== this._requestedContactEmail);
	}

	handleSoloTransferFinalConfirmClick() {
		console.log('handleSoloTransferFinalConfirmClick');

		this._isSpinner = true;
		submitSoloTransfer({params: {
			selectedParticipantId: this._selectedSoloTransferParticipantId,
			communityContactId: this._communityContactId,
			communityContactEmail: this._communityContactEmail,
			requestedContactId: this._requestedContactId,
			requestedContactEmail: this._requestedContactEmail,
			crDescription: this._crDescription
			}}).then(result=>{
				console.log('result: ', result);
				this._isError = false;
				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					this.showErrorToast(result.message);
				}

				this.connectedCallback();
			})
			.catch(error=>{
				console.log('ChangeRequestComponent');
				console.log('handleSoloTransferFinalConfirmClick Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})


	}

	handleSoloTransferFinalCancelClick() {
		console.log('handleSoloTransferFinalCancelClick');
		this._displaySoloTransferContainer = false;
		this._displayChangeRequestCancelButton = true;
	}

	//	GROUP CANCELLATION BLOCK
	handleSubmitGroupCancellation(event) {
		const selectedGroupId = event.detail.selectedGroupId;
		console.log('handleSubmitGroupCancellation selectedGroupId: ', selectedGroupId);

		submitGroupCancellation({params: {
			selectedContactId: this._communityContactId,
			crDescription: this._crDescription,
			selectedGroupId: selectedGroupId
			}}).then(result=>{
				console.log('result: ', result);
				this._isError = false;
				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					this.showErrorToast(result.message);
				}

				this.connectedCallback();
			})
			.catch(error=>{
				console.log('ChangeRequestComponent');
				console.log('submitGroupCancellation Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})

	}

	//	GROUP TRANSFER BLOCK
	handleSubmitGroupTransfer(event) {
		const selectedGroupId = event.detail.selectedGroupId;
		console.log('handleSubmitGroupTransfer selectedGroupId: ', selectedGroupId);

		var params = {};
		params.selectedCRType = this._selectedCRType;
		params.contactRecordId = this.recordId;
		params.selectedGroupId = selectedGroupId;
		this._paramsString = JSON.stringify(params);

		this._selectedGroupIdForTransfer = selectedGroupId;
		this._displayMyRegistrationsComponent = false;
		this._displayGroupTransferContainer = true;
		this._displayChangeRequestCancelButton = false;
	}


	handleGroupTransferFinalSubmitClick(event) {
		console.log('handleGroupTransferFinalSubmitClick');
		var eventparams = event.detail.eventparams;
		console.log('eventparams: ', eventparams);
		this._displayGroupTransferContainer = false;

		this._isSpinner = true;
		submitGroupTransfer({params: {
			eventparams: eventparams,
			crDescription: this._crDescription,
			selectedGroupId: this._selectedGroupIdForTransfer,
			communityContactId: this._communityContactId,
			}}).then(result=>{
				console.log('result: ', result);
				this._isError = false;
				this._isSpinner = false;

				if (result.result) {
					this.showSuccessToast(result.message);
				}
				if (!result.result) {
					this.showErrorToast(result.message);
				}

				this.connectedCallback();
			})
			.catch(error=>{
				console.log('handleGroupTransferFinalSubmitClick');
				console.log('handleGroupTransferFinalSubmitClick Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
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

	//	DELETE ???
	navigateCommunityPage(targetPageName, id){
		console.log('changeRequestComponent navigateCommunityPage targetPageName: ', targetPageName);
		console.log('changeRequestComponent navigateCommunityPage recordId: ', id);
		console.log('changeRequestComponent navigateCommunityPage this.params: ', this.params);
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: targetPageName,	// 'groupdetailspage',
				actionName: 'view'
			},
			state: {
				'recordId': id,
				'params': this.params
			}
		});
	}

}