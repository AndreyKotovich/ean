import {LightningElement, track} from 'lwc';
import getCurrentContactMemberships from '@salesforce/apex/MembershipContainerController.getCurrentContactMemberships';
import getExistedForm from '@salesforce/apex/membershipApplicationController.getExistedForm'
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";

export default class Membershipcontainer extends NavigationMixin(LightningElement) {
    newMembershipButton = false;
    upgradeMembershipButton = false;
    @track container = true;
    @track newMembershipApp = false;
    @track upgradeMembershipApp = false;
    @track allowMembershipRenewal = false;
    currentContactMemberships;
    connectedCallback() {
        let urlParams = new URL(window.location);
        let formId = urlParams.searchParams.get("fi"); //get application form id
        if(formId!=null && formId!==''){
                getExistedForm({formId: formId})
                    .then(result=>{
                        console.log('result:: '+JSON.stringify(result));
                        this.container = false;

                        if(result['Form_Status__c']==='Further Information Required'){
                            this.newMembershipApp = true;
                        } else if(result['Form_Status__c']==='Draft'){

                            switch (result['Order__r']['Purchase_Type__c']) {
                                case 'New':
                                    this.newMembershipApp = true;
                                    break;
                                case 'Update':
                                    getCurrentContactMemberships()
                                        .then(result=>{
                                            this.currentContactMemberships = [...JSON.parse(result)['memberships']];
                                            this.upgradeMembershipApp = true;
                                        })
                                        .catch(error=> {
                                            this.dispatchToast('Error', 'Something went wrong with files attachment. Please contact your system administrator.', 'error');
                                            console.log(error);
                                        });
                                    break;
                                default:
                                    this.dispatchToast('Error', 'Can\'t define application type. Please, contact your system administrator.', 'error');
                            }

                        } else {
                            this.dispatchToast('Error', 'This application not available for editing.', 'error');
                        }
                    })
                    .catch(error=>{
                        console.log('ERROR_container_getExistedForm');
                        let message = '';
                        if(!error.body.message.includes('_')){
                            message = error.body.message;
                        } else {
                            message = 'Something went wrong';
                            console.log('checkUrlParams_ERROR: ' + JSON.stringify(error));
                        }
                        //redirect to membership application page
                        this.dispatchToast('Error', message, 'error');
                        this.isSpinner = false;
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'membership-application'
                            },
                        });
                    });
        } else {
            getCurrentContactMemberships()
                .then(result=>{
                    // console.log('getCurrentContactMemberships result: ', result);
                    this.currentContactMemberships = [...JSON.parse(result)['memberships']];
                    this.manageButtons(result);
                })
                .catch(error=> {
                    console.log(error);
                });
        }
    }
    manageButtons(result){
        let parsedResult = JSON.parse(result);
        if(parsedResult['memberships'].length === 0){
            //new
            this.newMembershipButton = true;
            parsedResult['app-forms'].forEach(item=>{
                if(item['Form_Status__c'] === 'Submitted' || item['Form_Status__c'] === 'Complete' || item['Form_Status__c'] === 'Further Information Required'){
                    console.log('here');
                    console.log(item);
                    this.newMembershipButton = false;
                }
            });
        } else if(parsedResult['memberships'].length >= 1) {
            //upgrade
            parsedResult['memberships'].forEach(item=>{
                let membershipApi = item['Membership__r']['API__c'];
                if(membershipApi==='associate_individual_membership'
                    || membershipApi==='full_membership'
                    || membershipApi==='resident_and_research_membership'
                    || membershipApi==='student_membership'
                    || membershipApi==='associate_corresponding_membership'){

                    this.upgradeMembershipButton = true;

                }
            });
        }
        //  part of 'Membership Renewal'
        if (parsedResult.renewalSettings.displayMembershipRenewalButton) {
            // console.log('parsedResult: ', parsedResult);
            this.allowMembershipRenewal = true;
            this.template.querySelector('button[name="membership-renewal-button"]').removeAttribute('disabled');
        }

        if(this.newMembershipButton){
            this.template.querySelector('button[name="new-membership-button"]').removeAttribute('disabled');
        }

        if(this.upgradeMembershipButton){
            this.template.querySelector('button[name="update-membership-button"]').removeAttribute('disabled');

            //  part of 'Membership Renewal'
            let urlParams = new URL(window.location);
            let membershipStatusId = urlParams.searchParams.get("re");
            console.log('Membershipcontainer membershipStatusId: ', membershipStatusId);
            if (membershipStatusId) {
                this.openUpdateMembershipApp();
            }
        }
    }
    openNewMembershipApp(){
        if(this.newMembershipButton){
            this.container = false;
            this.newMembershipApp = true;
        }
    }
    openUpdateMembershipApp(){
        if(this.upgradeMembershipButton){
            this.container = false;
            this.upgradeMembershipApp = true;
        }
    }
    handleMembershipRenewal(){
        if(this.allowMembershipRenewal){
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'membership-renewal'
                },
            });
        }
    }
    dispatchToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }
}