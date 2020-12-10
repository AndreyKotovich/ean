import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getPreparedData from '@salesforce/apex/MembershipRenewalController.getAppFormInfo';
import updateAppFormApproval from '@salesforce/apex/MembershipRenewalController.updateAppFormApproval';

export default class MembershipRenewalApprovalComponent extends NavigationMixin(LightningElement) {
	@api recordId;

	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_errorMessageCustom = '';
	_displayErrorMessageCustom = false;
	_isSpinner = true;
	_isError = false;

	_headerText = 'Review of:';
	_appFormId = '';
	_appFormName = '';
	_formStatus = '';
	_comment = '';
	_contactId = '';
	_contactEmail = '';

	_displayOnlyCancelButton = true;

	connectedCallback() {
		this._isSpinner = true;

		getPreparedData({params: {recordId: this.recordId}}).then(result=>{
			this._displayErrorMessageCustom = false;
			this._isSpinner = false;

			if (!result.result) {
				console.log('result: ', result);
				this._isError = true;
				this._headerText = result.appFormName;

				if (result.isCustomError && result.message) {
					this._errorMessageCustom = result.message;
					this._displayErrorMessageCustom = true;
				}
				return;
			}

			this._isError = false;
			this._appFormId = result.appFormId;
			this._headerText = 'Review of: ' + result.appFormName;
			this._appFormName = 'Review of: ' + result.appFormName;
			this._formStatus = result.formStatus;
			this._contactId = result.contactId;
			this._contactEmail = result.contactEmail;
			this._displayOnlyCancelButton = false;
		})
		.catch(error=>{
			console.log('membershipRenewalApprovalComponent error: ', error);
			console.log('connectedCallback Error: ' + JSON.stringify(error));
			this._isError = true;
			this._isSpinner = false;
			this._displayErrorMessageCustom = false;
			this._headerText = 'Internal Error';
		})
	}

	handleCommentChange(event) {
		let target = this.template.querySelector('[data-target-id="standardtextarea"]');
		let commentText = target.value;
		this._comment = commentText;
	}

	clickApprove() {
		this.processAppForm('Approve');
	}

	clickFinalReject() {
		this.processAppForm('Reject');
	}

	clickMoreInfo() {
		this.processAppForm('MoreInfo');
	}


	processAppForm(methodName) {
		this._isSpinner = true;

		updateAppFormApproval({params: {
			action: methodName,
			appFormId: this._appFormId,
			comment: this._comment,
			formStatus: this._formStatus,
			contactId: this._contactId,
			contactEmail: this._contactEmail
			}}).then(result=>{
				console.log('result: ', result);
				this._displayErrorMessageCustom = false;
				this._isSpinner = false;

				if (!result.result) {
					console.log('result: ', result);
					this._isError = true;

					if (result.isCustomError && result.message) {
						this._errorMessageCustom = result.message;
						this._displayErrorMessageCustom = true;
						this._displayOnlyCancelButton = true;
					}
					return;
				}

				const evt = new ShowToastEvent({
					title: 'Success',
					message: 'Success',
					variant: 'success',
					mode: 'dismissable'
				});
				this.dispatchEvent(evt);
				this.navigateToNewRecordPage(this._appFormId);
				this.closeQuickAction();
			})
			.catch(error=>{
				console.log('membershipRenewalApprovalComponent error: ', error);
				console.log('processAppForm Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
				this._displayErrorMessageCustom = false;
				this._displayOnlyCancelButton = true;
				this._headerText = 'Internal Error';
			})
	}

	closeQuickAction() {
		const closeQA = new CustomEvent('close');
		this.dispatchEvent(closeQA);
	}

    navigateToNewRecordPage(id) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                'recordId': id,
                'actionName': 'view'
            },
        });
    }

}