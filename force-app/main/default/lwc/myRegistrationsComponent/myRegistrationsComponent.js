import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import connectedCallbackApex from '@salesforce/apex/MyRegistrationsController.connectedCallbackApex'

export default class MyRegistrationsComponent extends NavigationMixin(LightningElement) {

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

	connectedCallback() {
		console.log('connectedCallback');
		connectedCallbackApex()
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
		this.navigateToRecordPage(participantId);
	}

	handleClickOnGroupRegistration(event){
		console.log('handleClickOnGroupRegistration');
		var registrationGroupId = event.currentTarget.dataset.id;
		console.log('registrationGroupId: ', registrationGroupId);
		
		//	TODO
		//	navigate to configure/update group registration
		//	new window or popup ???
		this.navigateToGroupDetailsPage(registrationGroupId);

	}

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
				'recordId': id
			}
		});
	}


}