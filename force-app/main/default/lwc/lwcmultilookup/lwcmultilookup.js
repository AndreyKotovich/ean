import { LightningElement,api,track } from 'lwc';
import getResults from '@salesforce/apex/lwcMultiLookupController.getResults';
import contactId from '@salesforce/schema/User.ContactId';

export default class LwcMultiLookup extends LightningElement {
    @api objectname ;
    @api fieldname;
    @api Label;
    @track searchRecords = [];
    @track selectedRecords = [];
    @api defaultrecords = [];
    @api required = false;
    @api iconname = '';
    @api LoadingText = false;
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track messageFlag = false;

    connectedCallback() {
        this.setDefaultRecords();
    }

    searchField(event) {

        const currentText = event.target.value;
        let selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.LoadingText = true;
        getResults({ ObjectName: this.objectname, fieldName: this.fieldname, value: currentText, selectedRecId : selectRecId})
            .then(result => {
                this.searchRecords= result;
                this.LoadingText = false;

                this.txtclassname =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
                if(currentText.length > 0 && result.length === 0) {
                    this.messageFlag = true;
                }
                else {
                    this.messageFlag = false;
                }

                if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                    this.iconFlag = false;
                    this.clearIconFlag = true;
                }
                else {
                    this.iconFlag = true;
                    this.clearIconFlag = false;
                }
            })
            .catch(error => {
                console.log('-------error-------------'+JSON.stringify(error));
                console.log(error);
            });
    }

    setSelectedRecord(event) {
        const recId = event.currentTarget.dataset.id;
        const selectName = event.currentTarget.dataset.name;
        let newsObject = { 'recId' : recId ,'recName' : selectName };
        this.selectedRecords.push(newsObject);
        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        let selRecords = this.selectedRecords;
        this.template.querySelectorAll('lightning-input').forEach(each => {
            each.value = '';
        });
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    setDefaultRecords(){
        console.info('default records: ', this.defaultrecords);
         this.defaultrecords.forEach(each => {
             let newsObject = { 'recId' : each.recId ,'recName' : each.selectName };
             this.selectedRecords.push(newsObject);
             this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
         });
    }

    removeRecord (event){
        let selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].recId)
                selectRecId.push(this.selectedRecords[i]);
        }
        this.selectedRecords = [...selectRecId];
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}