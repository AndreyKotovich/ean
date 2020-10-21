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
	@api disabledtoedit;

	@api selectedRecordDetails;

	_initialized = false;
	_values = [];

	_datalistId = '';
	_recordIdToDetailsMap;
	_enabledtoedit = true;
	_lastenteredtext = '';
	_lastServerResults = [];

    renderedCallback() {
        if (this._initialized || !this._enabledtoedit) {
            return;
        }
		this._initialized = true;

		let listId = this.template.querySelector('datalist').id;
		this.template.querySelector("input").setAttribute("list", listId);
    }

	connectedCallback() {
		if (this.uniquekey1 == null) {
			this.uniquekey1 = '1234567890';
			this.uniquekey2 = 0;
		}

		this._enabledtoedit = this.disabledtoedit == undefined || this.disabledtoedit == null || this.disabledtoedit == false || this.disabledtoedit == 'false' ? true : false;
		this._datalistId = '' + this.uniquekey1 + this.uniquekey2;
		this.serverCall();
	}

    handleChange(evt) {
		var newEnteredText = evt.target.value;
		this._lastenteredtext = this.enteredtext;
		this.enteredtext = newEnteredText;
		if (newEnteredText.startsWith(this._lastenteredtext) && this._lastServerResults.length <= 0) return;
		if (this._lastenteredtext == newEnteredText) return;
		this.serverCall();
    }

	serverCall() {
		searchRecordsInDatabase(
			{listfields: this.listfields, objectname: this.objectname, searchfield: this.searchfield, searchtext: this.enteredtext, whereclause: this.whereclause, limitrecords: this.limitrecords, disabledvalues: this.disabledvalues}
			).then(result=>{
			console.log('serverCall result: ', result);

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
			this.dispatchEvent(new CustomEvent('changenewcontactemail', { bubbles: true, detail: { recorddetails: JSON.stringify(this.selectedRecordDetails), uniquekey1: this.uniquekey1, uniquekey2: this.uniquekey2 } }));
		})
		.catch(error=>{
			console.log('RecordSearch component');
			console.log('searchRecordsInDatabase Error: ' + JSON.stringify(error));
		})
	}


}