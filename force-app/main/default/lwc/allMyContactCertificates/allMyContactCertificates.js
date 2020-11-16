import { LightningElement } from 'lwc';
import getContactCertificates from '@salesforce/apex/AllMyContactCertificatesController.getContactCertificates';

export default class AllMyContactCertificates extends LightningElement {
	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_isSpinner = true;
	_isError = false;

	_displayComponent = false;
	_certificateDetailsList = false;

	connectedCallback() {
		this._isSpinner = true;
		this._isStep1 = false;

		getContactCertificates().then(result=>{
				// console.log('result: ', result);
				this._isSpinner = false;

				if (!result.result) {
					console.log('result: ', result);
					this._isError = true;
					return;
				}

				if (!result.displayComponent) {
					console.log('result: ', result);
					return;
				}

				this._isError = false;
				this._displayComponent = true;
				this._certificateDetailsList = result.certificateDetailsList;
			})
			.catch(error=>{
				console.log('allMyContactCertificates error: ', error);
				console.log('connectedCallback Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

}