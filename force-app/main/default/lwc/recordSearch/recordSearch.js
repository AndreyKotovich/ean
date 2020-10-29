import { LightningElement, api } from 'lwc';
import searchRecordsInDatabase from '@salesforce/apex/RecordSearchController.searchRecordsInDatabase'

//	TODO:
//	change implementation to dropdown
//	use recordId (not entered text) for get record detals

export default class RecordSearch extends LightningElement {

	@api listfields;
	@api objectname;
	@api searchfield;
	@api whereclause;
	@api limitrecords;
	@api enteredtext;
	@api existingrecordid;
	@api placeholder;
	@api inputtype;		//	text, password, datetime, datetime-local, date, month, time, week, number, email, url, search, tel, and color
	@api lookupicon;
	@api uniquekey1;		//	component instance/tag unique key 1
	@api uniquekey2;		//	component instance/tag unique key 2
	@api disabledvalues;	//	list string in JSON (only for text search)
	@api enabledvalue;
	@api disabledtoedit;

	@api selectedRecordDetails = {};

	_initialized = false;
	_values = [];

	_datalistId = '';
	_recordIdToDetailsMap;
	_enabledtoedit = true;
	_lastenteredtext = '';
	_lastServerResults = [];
	_originaltext = '';

	//	prevent browser autofill
	_inputName = 'incust';

    renderedCallback() {
		if (this.enteredtext != undefined) {
			this._lastenteredtext = this.enteredtext;
		}
		if (this.enteredtext == undefined) {
			this.enteredtext = this._lastenteredtext;
		}
        if (this._initialized || !this._enabledtoedit) {
            return;
		}
		
		// console.log('renderedCallback this.enteredtext: ', this.enteredtext);
		this._originaltext = this.enteredtext;

		this._initialized = true;

		let listId = this.template.querySelector('datalist').id;
		this.template.querySelector("input").setAttribute("list", listId);
		// this.template.querySelector(this._datalistId).setAttribute("list", listId);
    }

	connectedCallback() {
		if (this.uniquekey1 == null) {
			this.uniquekey1 = '1234567890';
			this.uniquekey2 = 0;
		}

		this._enabledtoedit = this.disabledtoedit == undefined || this.disabledtoedit == null || this.disabledtoedit == false || this.disabledtoedit == 'false' ? true : false;
		this._datalistId = '' + this.uniquekey1 + this.uniquekey2;
		// this.serverCall();

		//	prevent browser autofill
		var charset = "abcdefghijklmnopqrstuvwxyz0123456789";
		for (var i = 0; i < 16; i++) this._inputName += charset.charAt(Math.floor(Math.random() * charset.length));
	}

    handleChange(evt) {
		var newEnteredText = evt.target.value;
		if (newEnteredText == undefined) {
			// console.log('handleChange return 1');
			return;
		}

		this._lastenteredtext = this.enteredtext;
		this.enteredtext = newEnteredText;
		if (this._lastenteredtext != '' && newEnteredText.startsWith(this._lastenteredtext) && this._lastServerResults.length <= 0) {
			// console.log('handleChange return 2');
			this.selectedRecordDetails.enteredText = this.enteredtext;
			this.selectedRecordDetails.originalText = this._originaltext;
			this.dispatchEvent(new CustomEvent('changenewcontactemail', { bubbles: true, detail: { recorddetails: JSON.stringify(this.selectedRecordDetails), uniquekey1: this.uniquekey1, uniquekey2: this.uniquekey2 } }));
			this._originaltext = this.enteredtext;
			return;
		}
		if (this._lastenteredtext == newEnteredText) {
			// console.log('handleChange return 3');
			return;
		}

		this.serverCall();
    }

	serverCall() {
		// console.log('serverCall this.enteredtext: ', this.enteredtext);
		searchRecordsInDatabase(
			{
				listfields: this.listfields, objectname: this.objectname,
				searchfield: this.searchfield, searchtext: this.enteredtext,
				whereclause: this.whereclause, limitrecords: this.limitrecords,
				disabledvalues: this.disabledvalues,
				enabledvalue: this.enabledvalue
			}).then(result=>{
			// console.log('serverCall result: ', result);

			this._values = [];
			this._emailToDetails = new Map();
			this.selectedRecordDetails = {};
			var serverResults = JSON.parse(result);
			if (serverResults.length <= 0) {
				// no results
			} else {
				for (var i = 0; i < serverResults.length; i++) {
					var value = {recordId: serverResults[i].id, textvalue: serverResults[i].text};
					this._values.push(value);
					if (serverResults[i].text == this.enteredtext) {
						this.selectedRecordDetails = serverResults[i];
					}
				}
			}
			this._lastServerResults = serverResults;
			this.selectedRecordDetails.enteredText = this.enteredtext;
			this.selectedRecordDetails.originalText = this._originaltext;
			this.dispatchEvent(new CustomEvent('changenewcontactemail', { bubbles: true, detail: { recorddetails: JSON.stringify(this.selectedRecordDetails), uniquekey1: this.uniquekey1, uniquekey2: this.uniquekey2 } }));
			this._originaltext = this.enteredtext;
		})
		.catch(error=>{
			console.log('RecordSearch component');
			console.log('searchRecordsInDatabase Error: ' + JSON.stringify(error));
		})
	}


}