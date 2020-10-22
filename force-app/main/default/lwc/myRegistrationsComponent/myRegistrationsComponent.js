import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getMyRegistrations from '@salesforce/apex/MyRegistrationsController.getMyRegistrations'

export default class MyRegistrationsComponent extends NavigationMixin(LightningElement) {

	@api params;
	// @api contactRecordId;

	_callbackResult;
	_callbackResultString = '';	// DELETE

	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_noRegistrationMessage = 'You have no registrations.'
	_isSpinner = true;
	_isError = false;
	
	_contactId;
	_accountId;
	_registrationsSolo;
	_displayRegistrationsSolo;
	_registrationsGroup;
	_displayRegistrationsGroup;
	_displayNoRegistrationMessage = false;
	_myRegistrationsLabel;
	_myRegisteredGroupsLabel;
	_displayCRUnavailableMessage = false;
	_crUnavailableMessage = '';
	_selectedCRType = '';

	connectedCallback() {
		console.log('myRegistrationsComponent connectedCallback');
		console.log('myRegistrationsComponent connectedCallback this.params: ', JSON.stringify(this.params));
		getMyRegistrations({settings: {
			params: this.params
			}})
			.then(result=>{
				console.log('result: ', result);
				this._callbackResult = result;
				this._callbackResultString = JSON.stringify(result);	// DELETE
				this._isError = false;
				this._isSpinner = false;

				this._contactId = result.contactId;
				this._accountId = result.accountId;
				this._registrationsSolo = result.registrationsSolo;
				this._registrationsGroup = result.registrationsGroup;
				this._displayRegistrationsSolo = result.displayRegistrationsSolo;
				this._displayRegistrationsGroup = result.displayRegistrationsGroup;
				this._displayNoRegistrationMessage = result.displayNoRegistrationMessage;
				this._myRegistrationsLabel = result.myRegistrationsLabel
				this._myRegisteredGroupsLabel = result.myRegisteredGroupsLabel
				this._displayCRUnavailableMessage = result.displayCRUnavailableMessage;
				this._crUnavailableMessage = result.crUnavailableMessage;
				this._selectedCRType = result.selectedCRType;
			})
			.catch(error=>{
				console.log('MyRegistrationsComponent component');
				console.log('connectedCallbackApex Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	handleClickOnMyRegistration(event){
		console.log('handleClickOnMyRegistration');
		var participantId = event.currentTarget.dataset.id;
		console.log('participantId: ', participantId);
		if (this._selectedCRType == '') {
			this.navigateToRecordPage(participantId);
			return;
		}

		if (this._selectedCRType == 'Solo Registration Cancellation') {
			this.dispatchEvent(new CustomEvent('submitsolocancellation', { bubbles: true, detail: { selectedParticipantId: participantId } }));
		}

		if (this._selectedCRType == 'Solo Registration Transfer') {
			this.dispatchEvent(new CustomEvent('submitsolotransfer', { bubbles: true, detail: { selectedParticipantId: participantId } }));
		}

	}

	handleClickOnGroupRegistration(event){
		console.log('handleClickOnGroupRegistration this._selectedCRType: ', this._selectedCRType);
		var registrationGroupId = event.currentTarget.dataset.id;
		console.log('registrationGroupId: ', registrationGroupId);
		
		//	navigate to configure/update group registration
		if (this._selectedCRType == '') {
			console.log('CONSOLE 1');
			this.navigateToGroupDetailsPage(registrationGroupId);
			console.log('CONSOLE 2');
			return;
		}

		if (this._selectedCRType == 'Group Registration Cancellation') {
			console.log('CONSOLE 3');
			this.dispatchEvent(new CustomEvent('submitgroupcancellation', { bubbles: true, detail: { selectedGroupId: registrationGroupId } }));
			console.log('CONSOLE 4');
		}

		if (this._selectedCRType == 'Group Registration Transfer') {
			console.log('CONSOLE 5');
			this.dispatchEvent(new CustomEvent('submitgrouptransfer', { bubbles: true, detail: { selectedGroupId: registrationGroupId } }));
			console.log('CONSOLE 6');
		}

	}

	//	TODO CREATE NEW CHANGE REQUEST
	navigateToRecordPage(id) {
		console.log('navigateToRecordPage participantId: ', id);
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				'recordId': id,
				actionName: 'view'
			},
		});
	}

	navigateToGroupDetailsPage(id){
		console.log('navigateToGroupDetailsPage registrationGroupId: ', id);
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				// 'recordId': id,
				pageName: 'groupdetailspage',
				actionName: 'view'
			},
			state: {
				'recordId': id,
				'params': this.params
			}
		});
	}


}