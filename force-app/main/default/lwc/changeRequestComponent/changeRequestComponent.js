import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getPreparedData from '@salesforce/apex/ChangeRequestController.getPreparedData'

export default class ChangeRequestComponent extends NavigationMixin(LightningElement) {
	@api recordId;				// required to work as EAN Staff (Customer Contact Record Id)

	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_noRecordsMessage = 'You have no Change Requests.'
	_newRequestMessageLabel = 'Define New Change Request';
	_isSpinner = true;
	_isError = false;

	_changeRequestsList;
	_componentLabel;
	// _requestsTypeListMap;


	_displayNoRecordsMessage = false;
	_displayChangeRequestsPanel = false;
	_displayChangeRequestsList = false;
	_displayNewRequestDefinition = false;
	_displayTopButtons = false;
	_displayBottomButtons = false;
	_displayNewChangeRequestButton = false;
	_displayChangeRequestButtons = false;

	_displayChangeRequestPanel = true;
	_displayMyRegistrationsComponent = false;
	
	_paramsString;

	_crTypes = [];
	_selectedCRType;

	connectedCallback() {
		this._displayChangeRequestPanel = true;
		console.log('ChangeRequestComponent connectedCallback');
		console.log('this.recordId: ', this.recordId);

		getPreparedData({settings: {
			recordId: this.recordId
			}}).then(result=>{
				console.log('result: ', result);
				// this._callbackResult = result;
				// this._callbackResultString = JSON.stringify(result);	// DELETE
				this._isError = false;
				this._isSpinner = false;

				if (result.result) {
					console.log('result.result: ', result.result);
				}

				this._displayChangeRequestsPanel = true;
				this._changeRequestsList = result.changeRequestsList;
				this._displayNoRecordsMessage = result.displayNoRecordsMessage;
				this._displayChangeRequestsList = result.displayChangeRequestsList;
				this._componentLabel = result.componentLabel;
				this._displayTopButtons = result.displayTopButtons;
				this._displayBottomButtons = result.displayBottomButtons;
				this._displayNewChangeRequestButton = true;

				var requestsTypeListMap = result.requestsTypeListMap;
				this._selectedCRType = requestsTypeListMap[0].value
				for (var i = 0 ; i < requestsTypeListMap.length ; i++) {
					this._crTypes.push({label: requestsTypeListMap[i].label, value: requestsTypeListMap[i].value});
				}
				console.log('getPreparedData _crTypes: ', this._crTypes);

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
		this._displayChangeRequestButtons = true;
		this._displayChangeRequestsPanel = false;
		this._displayNewRequestDefinition = true;
	}

	//	'Solo Registration Cancelation'
	//	'Group Registration Cancelation'
	//	'Solo Registration Transfer'
	//	'Group Registration Transfer'
	handleConfirmClick() {
		console.log('handleConfirmClick this._selectedCRType: ', this._selectedCRType);
		this._displayNewChangeRequestButton = false;
		this._displayChangeRequestButtons = false;

		let target = this.template.querySelector('[data-target-id="standardtextarea"]');
		let commentText = target.value;
		console.log('handleConfirmClick commentText: ', commentText);

		var params = {};
		params.selectedCRType = this._selectedCRType;
		params.contactRecordId = this.recordId;
		this._paramsString = JSON.stringify(params);

		var redirectToMyRegistrationsPage = ['Solo Registration Cancelation', 'Group Registration Cancelation', 'Solo Registration Transfer', 'Group Registration Transfer'];

		if (redirectToMyRegistrationsPage.includes(this._selectedCRType)) {
			console.log('FFFF _params: ', params);
			this._displayChangeRequestPanel = false;
			this._displayMyRegistrationsComponent = true;
			// navigateCommunityPage(targetPageName, id);
		}

	}

	handleCancelClick() {
		console.log('handleCancelClick');
		this._displayNewChangeRequestButton = true;
		this._displayChangeRequestButtons = false;
		this._displayChangeRequestsPanel = true;
		this._displayNewRequestDefinition = false;
	}

	handleChangeCRType(event) {
		console.log('handleChangeCRType');
		this._selectedCRType = event.detail.value;
		console.log('handleChangeCRType this._selectedCRType: ', this._selectedCRType);
	}

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