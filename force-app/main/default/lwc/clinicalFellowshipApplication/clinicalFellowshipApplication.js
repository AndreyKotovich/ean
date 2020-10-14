import {LightningElement, track} from 'lwc';
import init from '@salesforce/apex/ClinicalFellowshipApplicationController.init'
import deleteContentDocumentById from '@salesforce/apex/membershipApplicationController.deleteContentDocumentById'
import createAppForm from '@salesforce/apex/ClinicalFellowshipApplicationController.createAppForm'
import attachFileToForm from '@salesforce/apex/membershipApplicationController.attachFileToForm'
import submitRecordForApproval from '@salesforce/apex/ClinicalFellowshipApplicationController.submitRecordForApproval'
import { NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
export default class ClinicalFellowshipApplication extends NavigationMixin(LightningElement) {
    @track isSpinner = false;
    @track showInputForm = false;
    @track recordTypeId = '';
    @track contact = {};
    @track uploadedFilesPills=[];
    @track contactDepartments = [];
    @track fellowshipApplication={};
    connectedCallback() {
        this.getUrlAttributes();
        this.isSpinner = true;
        init()
            .then(result => {
                this.recordTypeId = result['record-type-id'];
                this.contact = Object.assign({}, JSON.parse(result['contact']));
                this.isSpinner = false;
                this.showInputForm = true;
            })
            .catch(error => {
                if(!error.body.message.includes('ERROR_')){
                    this.dispatchToast('Error', error.body.message, 'error');
                }else {
                    console.log('init_error: '+error.body.message)
                }
                this.isSpinner = false;
            });
    }
    getUrlAttributes(){
        let urlParams = new URL(window.location);
        if(urlParams.searchParams.get("fellowship-id")!=null){
            this.fellowshipApplication['Fellowship__c'] = urlParams.searchParams.get("fellowship-id");
        }
    }
    dispatchToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }
    handleInputChange(event){
        this.fellowshipApplication[event.target['name']] = event.target['value'];
    }
    get acceptedFormats() {
        return ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
    }
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        let uploadedFilesPills=[...this.uploadedFilesPills];
        uploadedFiles.forEach(item=>{
            uploadedFilesPills.push({
                type: 'icon',
                label: item.name,
                iconName: 'doctype:attachment',
                documentId: item.documentId,
            });
        });
        this.uploadedFilesPills = [...uploadedFilesPills];
        this.manageDisplayPillsSection();
    }
    handleRemoveFilePill(event){
        const index = event.detail.index;
        this.uploadedFilesPills.splice(index, 1);
        this.uploadedFilesPills = [...this.uploadedFilesPills];
        deleteContentDocumentById({docId:event.detail.item.documentId});
        this.manageDisplayPillsSection();
    }
    manageDisplayPillsSection(){
        if(this.uploadedFilesPills.length>0){
            let divContainer = this.template.querySelector('div[title="pill-container"]');
            if(divContainer.style.display === 'none'){
                divContainer.style.display = 'block';
            }
        }
        if(this.uploadedFilesPills.length===0){
            let divContainer = this.template.querySelector('div[title="pill-container"]');
            if(divContainer.style.display === 'block'){
                divContainer.style.display = 'none';
            }
        }
    }
    attachFilesToAppForm(form){
        let uploadedFilesPills = [...this.uploadedFilesPills];
        let contentDocumentLinks = [];
        uploadedFilesPills.forEach(item=>{
            contentDocumentLinks.push({
                ContentDocumentId : item.documentId,
                LinkedEntityId : form.Id,
                ShareType : 'I',
                Visibility : 'AllUsers',
            });
        });
        attachFileToForm({contentDocumentLinks:contentDocumentLinks})
            .then(()=>{})
            .catch(error=>{
            console.log('attachFileToForm_error: '+JSON.stringify(error));
        })
    }
    handleClickSubmit(){
        this.isSpinner = true;
        this.fellowshipApplication['Contact__c'] = this.contact.Id;
        this.fellowshipApplication['RecordTypeId'] = this.recordTypeId;
        createAppForm({fellForm:this.fellowshipApplication})
            .then(fellForm=>{
                submitRecordForApproval({recordId:fellForm.Id})
                    .then(result=>{
                        this.isSpinner = false;
                        if(result){
                            this.dispatchToast('Success', 'Submitted for approval', 'success');
                            this.navigateToRecordPage(fellForm.Id);
                        } else {
                            this.dispatchToast('Error', 'Something went wrong', 'error');
                        }
                    })
                    .catch(error=>{
                        console.log('submitRecordForApproval_error: '+JSON.stringify(error));
                        this.dispatchToast('Error', 'Something went wrong', 'error');
                        this.isSpinner = false;
                    });
                this.attachFilesToAppForm(fellForm);
            })
            .catch(error=>{
                this.dispatchToast('Error', 'Something went wrong', 'error');
                console.log('createAppForm_error: '+JSON.stringify(error));
            })
    }
    navigateToRecordPage(recordId){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        });
    }
}