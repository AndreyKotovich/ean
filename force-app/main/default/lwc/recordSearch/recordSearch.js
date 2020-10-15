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
	@api uniquekey2;		//	component instance/tag unique key 1
	@api disabledvalues;	//	list string in JSON (only for text search)
	@api disabledtoedit;

	@api selectedRecordDetails;

	_initialized = false;
	_values = [];
	_selectedId = '';

	_datalistId = '';
	_recordIdToDetailsMap;
	// _emailToDetails;
	_enabledtoedit = true;


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
			console.log('recordSearch connectedCallback this.uniquekey1', this.uniquekey1);
			console.log('recordSearch connectedCallback this.uniquekey2', this.uniquekey2);
			this.uniquekey1 = '1234567890';
			this.uniquekey2 = 0;
		}

		console.log('RecordSearch 111 connectedCallback this.disabledtoedit: ', this.disabledtoedit);
		if (this.disabledtoedit === undefined) {
			console.log('RecordSearch 11 UNDEFINED');
			this._enabledtoedit = false;
		}
		if (this.disabledtoedit === null) {
			console.log('RecordSearch 22 NULL');
		}
		if (this.disabledtoedit === 'false') {
			console.log('RecordSearch 33 false');
		}

		this._enabledtoedit = this.disabledtoedit == undefined || this.disabledtoedit == null || this.disabledtoedit == false || this.disabledtoedit == 'false' ? true : false;
		console.log('RecordSearch 111 connectedCallback this._enabledtoedit: ', this._enabledtoedit);

		this._datalistId = '' + this.uniquekey1 + this.uniquekey2;

		console.log('RecordSearch connectedCallback');
		console.log('RecordSearch connectedCallback this.enteredtext: ', this.enteredtext);
		this.serverCall();
	}

    handleChange(evt) {
		console.log('handleChange');
		var newEnteredText = evt.target.value;
		console.log('newEnteredText: ', newEnteredText);

		if (this.enteredtext == newEnteredText) return;

		console.log('RecordSearch handleChange 000 this.enteredtext: ', this.enteredtext);

		this.enteredtext = newEnteredText;
		this.serverCall();
    }

	serverCall() {
		searchRecordsInDatabase(
			{listfields: this.listfields, objectname: this.objectname, searchfield: this.searchfield, searchtext: this.enteredtext, whereclause: this.whereclause, limitrecords: this.limitrecords, disabledvalues: this.disabledvalues}
			).then(result=>{
			console.log('serverCall result: ', result);

			this._values = [];
			this._emailToDetails = new Map();
			this.selectedRecordDetails = null;

			var retObj = JSON.parse(result);
			if (retObj.length <= 0) {
				// no results
				this._selectedId = '';
			} else {
				for (var i = 0; i < retObj.length; i++) {
					var value = {recordId: retObj[i].id, textvalue: retObj[i].text};
					this._values.push(value);
					// this._emailToDetails.set(retObj[i].text, retObj[i]);
					if (retObj[i].text == this.enteredtext) {
						this.selectedRecordDetails = retObj[i];
					}
				}

				// this.selectedRecordDetails = this._emailToDetails.get(this.enteredtext);
			}
			// console.log('serverCall this.selectedRecordDetails: ', this.selectedRecordDetails);
			// console.log('serverCall this.uniquekey1: ', this.uniquekey1);
			// console.log('serverCall this.uniquekey2: ', this.uniquekey2);

			this.dispatchEvent(new CustomEvent('groupchangecontactemail', { bubbles: true, detail: { recorddetails: JSON.stringify(this.selectedRecordDetails), uniquekey1: this.uniquekey1, uniquekey2: this.uniquekey2 } }));

		})
		.catch(error=>{
			console.log('RecordSearch component');
			console.log('searchRecordsInDatabase Error: ' + JSON.stringify(error));
		})
	}


}