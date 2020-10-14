import {LightningElement, api, track} from 'lwc';
import sObjectCheck from '@salesforce/apex/ApprovalCommentsController.sObjectCheck'
import getApprovalComments from '@salesforce/apex/ApprovalCommentsController.getApprovalComments'
import {NavigationMixin} from "lightning/navigation";
export default class ApprovalComments extends NavigationMixin(LightningElement) {
    @api recordId;
    @track componentFlag = false;
    @track post;
    @track postScreen = false;
    connectedCallback() {
        if(this.recordId!=null){
            sObjectCheck({recordId: this.recordId})
                .then(result=>{
                    this.componentFlag = result;
                    if(result){
                        getApprovalComments({recordId: this.recordId})
                            .then(approvalPost=>{
                                if(approvalPost !== 'none'){
                                    this.post = JSON.parse(approvalPost);
                                    this.postScreen = true;
                                }
                            })
                    }
                })
                .catch(error=>{
                    console.log('error:: '+JSON.stringify(error))
            })
        }
    }
    handleClickReSubmit(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'membership-application'
            },
            state: {
                fi: this.recordId
            }
        });
    }
}