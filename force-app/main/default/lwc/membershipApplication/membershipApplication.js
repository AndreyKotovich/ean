import {LightningElement, track, api} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
// APEX
import getMemberships from '@salesforce/apex/membershipApplicationController.getMemberships';
import getCountries from '@salesforce/apex/membershipApplicationController.getCountries';
import updateContact from '@salesforce/apex/membershipApplicationController.updateContact';
import getFieldSets from '@salesforce/apex/membershipApplicationController.getFieldSets';
import upsertForm from '@salesforce/apex/membershipApplicationController.upsertForm';
import getDeadline from '@salesforce/apex/membershipApplicationController.getDeadline';
import submitForApproval from '@salesforce/apex/membershipApplicationController.submitForApproval'
import deleteContentDocumentById from '@salesforce/apex/membershipApplicationController.deleteContentDocumentById'
import generateOrder from '@salesforce/apex/OrderUtils.generateOrder'
import attachFileToForm from '@salesforce/apex/membershipApplicationController.attachFileToForm'
import updateOrderItems from '@salesforce/apex/OrderUtils.updateOrderItems'
import getExistedForm from '@salesforce/apex/membershipApplicationController.getExistedForm'
import getContentDocuments from '@salesforce/apex/membershipApplicationController.getContentDocuments'
import getOrderWithItems from '@salesforce/apex/membershipApplicationController.getOrderWithItems'
// CUSTOM LABELS
import ma_membershipDescr1 from '@salesforce/label/c.ma_membershipDescr1';
import ma_membershipDescr2 from '@salesforce/label/c.ma_membershipDescr2';
import ma_membershipDescr3 from '@salesforce/label/c.ma_membershipDescr3';


export default class MembershipApplication extends NavigationMixin(LightningElement) {
    @track region = '';
    @track allAvailableMemberships = [];
    @track radioButtonsLabels = [];
    @track isShowMemberships = false;
    @track allCountries = [];
    @track currentContactId;
    @track isForm = false;
    @track paymentForm = false;
    @track formId = '';
    @track validateForm = false;
    @track firstFieldValueSet = [];
    @track secondFieldValueSet = [];
    @track contact = {};
    @track autoFillCountries = {};
    @track contactHospitals = [];
    @track contactDepartments = [];
    @track products = [];
    @track productOptions = [];
    @track isShowProducts = false;
    @track isSpinner = true;
    @track showPillUploadedFiles = false;
    @track isReSubmit = false; // indicates if application form in Re-Submit mode.
    @track formValues = {};
    @track uploadedFilesPills=[];
    form = {};
    membershipId;
    lookupsResults = {};
    orderId = '';
    selectedProducts = [];
    Country__mdt = [];
    isEdit = false; // detects if "Back" button on validate screen was clicked
    availableMembershipsForApplying = {};
    applicationMode = '';
    label = {
        ma_membershipDescr1,
        ma_membershipDescr2,
        ma_membershipDescr3
    };

    connectedCallback() {
        this.checkUrlParams()
            .then(()=>{
                getMemberships()
                    .then(result => {
                        this.allAvailableMemberships = [...result.memberships];
                        this.countryPrices = [...result.countryPrices];
                        this.currentContactId = result.contact.Id;
                        this.products = [...result.availableProduct2s];
                        this.setProducts();
                        if (this.formId === '') {
                            this.contact = Object.assign({}, result.contact);
                            let contact = result.contact;
                            this.fieldMap = [...result.fieldMap];
                            let formValues = {};
                            for (let property in contact) {
                                if (contact.hasOwnProperty(property)) {
                                    this.fieldMap.forEach(item => {
                                        if (property === item.Contact_field__c) {
                                            formValues[item.Form_field__c] = contact[property];
                                        }
                                    });
                                }
                            }
                            this.formValues = Object.assign({}, formValues);
                            this.getCountryPriceAndDetermineRegion();
                        }
                        this.getFieldSetsAndAutoCompleteForm();
                        this.handleCountryPrices();

                        if(this.applicationMode === 'EDIT'){
                            this.fieldMap = [...result.fieldMap];
                            for (let property in this.formValues) {
                                this.fieldMap.forEach(item => {
                                    if (property === item.Form_field__c) {
                                        this.contact[item.Contact_field__c] = this.formValues[property];
                                    }
                                });
                            }
                            this.contact['Id'] = this.currentContactId;
                        }

                    })
                    .catch(error => {
                        console.log(JSON.stringify(error));
                    });
            })
            .catch(()=>{
                console.log('this.checkUrlParams()_ERROR');
            });
    }

    checkUrlParams(){
        return new Promise((resolve, reject) => {
            let urlParams = new URL(window.location);
            let formId = urlParams.searchParams.get("fi"); //get application form id
            if(formId!=null && formId!==''){
                this.formId = formId;
                getExistedForm({formId: formId})
                    .then(result=>{
                        if(result['Form_Status__c']==='Further Information Required' || result['Form_Status__c']==='Draft') {
                            if(result['Form_Status__c']==='Further Information Required') this.isReSubmit = true;
                            this.membershipId = result['Membership__c'];
                            this.currentContactId = result['Contact__c'];
                            this.formValues = Object.assign({}, result);
                            this.getFieldSetsAndAutoCompleteForm();
                            getContentDocuments({LinkedEntityId: this.formId})
                                .then(documents => {
                                    let uploadedFilesPills = [];
                                    for (let document of documents) {
                                        uploadedFilesPills.push({
                                            type: "icon",
                                            label: document.ContentDocument.Title + '.' + document.ContentDocument.FileExtension,
                                            iconName: 'doctype:attachment',
                                            documentId: document.ContentDocument.Id
                                        });
                                    }
                                    this.uploadedFilesPills = [...uploadedFilesPills];
                                    if(result['Form_Status__c']==='Further Information Required'){
                                        this.validateForm = true;
                                        this.isSpinner = false;
                                    }
                                    this.manageDisplayPillsSection();
                                    if(result['Form_Status__c']==='Draft'){
                                        this.applicationMode = 'EDIT';
                                        this.getCountryPriceAndDetermineRegion();

                                        //get order items to autocomplete
                                        if(result.hasOwnProperty('Order__c')){
                                            this.orderId = result['Order__c'];
                                            this.isEdit = true;
                                            getOrderWithItems({orderId: result['Order__c']})
                                                .then(orderResult=>{
                                                    this.formOrderWithItems = Object.assign({}, orderResult);
                                                    if(this.formOrderWithItems.hasOwnProperty('orderItems')){
                                                        for(let orderItem of this.formOrderWithItems['orderItems']){
                                                            if(orderItem.hasOwnProperty('Product__c')){
                                                                this.selectedProducts.push(orderItem['Product__c']);
                                                            }
                                                        }
                                                    }
                                                    resolve();
                                                })
                                        }
                                    }
                                })
                        } else{
                            this.dispatchToast('Error', 'This application not available for editing.', 'error');
                            this.navigateToMembershipApplicationPage();
                        }
                    })
                    .catch(error=>{
                        console.log('ERROR_getExistedForm');
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
                        this.navigateToMembershipApplicationPage();
                    });
            } else {
                resolve();
            }
        });
    }

    navigateToMembershipApplicationPage(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'membership-application'
            },
        });
    }

    getFieldSetsAndAutoCompleteForm(){
        getFieldSets()
            .then(res => {
                this.firstFieldValueSet = this.createInputFieldObject(res[0]);
                this.secondFieldValueSet = this.createInputFieldObject(res[1]);
                this.isForm = true;
            })
            .catch(error => {
                console.log(JSON.stringify(error));
            });
    }

    getCountryPriceAndDetermineRegion() {
        getCountries()
            .then(result => {
                this.Country__mdt = [...result];
                let allCountries = [];
                result.forEach(country => {
                    allCountries.push({
                        label: country.Country__c,
                        value: (country.Region__c == null ? ' ' : country.Region__c) + ',' + country.Country__c
                    });
                    if (this.formValues.hasOwnProperty('Residency__c') && this.formValues.Residency__c === country.Country__c) {
                        //Determine user's region
                        this.region = country.Region__c;
                        this.handleCountryPrices();
                    }
                });
                this.allCountries = [...allCountries];
                this.allCountries.forEach(country => {
                    if (country.label === this.formValues.Residency__c) {
                        this.autoFillCountries.Residency__c = country.value;
                    }
                    if (country.label === this.formValues.Nationality__c) {
                        this.autoFillCountries.Nationality__c = country.value;
                    }
                });
            })
            .catch(error => {
                console.log(JSON.stringify(error));
            });
    }

    createInputFieldObject(arr) {
        let resultObject = [];
        arr.forEach(item => {
            let obj = {};
            obj.field = item;
            if (this.formValues.hasOwnProperty(item)) {
                obj.value = this.formValues[item];
            } else {
                obj.value = '';
            }
            resultObject.push(obj);
        });
        return resultObject;
    }

    handleCountryPrices() {
        this.isSpinner = true;
        getDeadline()
            .then(result => {
                let radioButtonsLabelsPromises = [];
                let radioButtonsLabels = [];
                this.allAvailableMemberships.forEach(membership => {
                    let isFound = false;
                    this.countryPrices.forEach(countryPrice => {
                        if (membership.Id === countryPrice.Membership__c) {
                            if (countryPrice.Region__c === this.region) {
                                isFound = true;
                                radioButtonsLabelsPromises.push(this.getRadioButtonLabel(countryPrice[result], membership, result));
                            }
                        }
                    });
                    if (!isFound) {
                        this.countryPrices.forEach(countryPrice => {
                            if (membership.Id === countryPrice.Membership__c) {
                                if (countryPrice.Region__c === 'Default') {
                                    radioButtonsLabelsPromises.push(this.getRadioButtonLabel(countryPrice[result], membership, result));
                                }
                            }
                        });
                    }
                });
                Promise.all(radioButtonsLabelsPromises)
                    .then(result =>{
                        for(let radioButtonLabel of result){
                            radioButtonsLabels.push(radioButtonLabel);
                        }
                        this.radioButtonsLabels = [...radioButtonsLabels];
                        this.isShowMemberships = true;
                        this.isSpinner = false;
                    });
            })
            .catch(error => {
                console.log('ERROR:: '+JSON.stringify(error));
            });
    }

    getRadioButtonLabel(initialPrice, membership, deadline){
        return new Promise((resolve, reject) => {
            let radioButtonLabel = {
                membershipId: membership.Id,
                membershipName: membership.Name,
                membershipAPI: membership.API__c,
                membershipWebsite: membership.www__c
            };
            //discounts logic
            let promises = [];
            if(this.formValues['AAN_Member__c']){
                promises.push(this.aanDiscount());
            }
            if(this.formValues['Retired__c']){
                promises.push(this.retiredDiscount(deadline, membership));
            }
            if(promises.length>0){
                Promise.all(promises)
                    .then(discountsList => {
                        let resultDiscount = 0;
                        for(let discount of discountsList){
                            resultDiscount+= discount;
                        }
                        radioButtonLabel.membershipPrice = initialPrice * (1 - resultDiscount/100);
                        resolve(radioButtonLabel);
                    });
            } else {
                radioButtonLabel.membershipPrice = initialPrice;
                resolve(radioButtonLabel);
            }
        });
    }

    aanDiscount(){
        return new Promise((resolve, reject) => {
            let discountPercent = 0;
            for(let country of this.Country__mdt){
                if(country['Country__c'] === this.formValues['Residency__c'] && !country['member_country__c']){
                    discountPercent = 10;
                }
            }
            resolve(discountPercent);
        });
    }

    retiredDiscount(deadline, membership){
        return new Promise((resolve, reject) => {
            let discountPercent = 0;
            if(this.region !== 'B' && this.region !== 'D'){
                if(deadline === 'price_for_deadline_1__c' || deadline === 'price_for_deadline_3__c'){
                    if(membership.API__c !== 'student_membership' && membership.API__c !== 'resident_and_research_membership'){
                        discountPercent = 50;
                    }
                }
            }
            resolve(discountPercent);

        });
    }

    onChangeMembership(event) {
        this.membershipId = event.target.title;
    }

    handleChangeCountry(event) {
        this.autoFillCountries[event.target.title] = event.detail.value;
        let arr = event.detail.value.split(',');
        this.region = arr[0];
        this.form[event.target.title] = arr[1];
        if (event.target.title === 'Residency__c') {
            this.handleCountryPrices();
        }
        this.writeValueToFormAndContactVariables(arr[1], event.target.title);
        this.manageMarkup();
    }

    handleChange(event) {
        this.writeValueToFormAndContactVariables(event.target.value, event.target.title);
        if (event.target.title === 'AAN_Member__c' || event.target.title === 'Retired__c') {
            this.handleCountryPrices();
        }
        this.manageMarkup();
    }

    writeValueToFormAndContactVariables(value, title) {
            this.formValues[title] = value;
            this.fieldMap.forEach(map => {
                if (map['Form_field__c'] === title) {
                    this.contact[map.Contact_field__c] = value;
                }
            });
    }

    filesValidation(){
        let filesFlag = true;
        let fileErrorMessage = 'In order to finalise your application, please do provide ';
        if(this.uploadedFilesPills.length === 0){
            this.radioButtonsLabels.forEach(item=>{
                if(this.membershipId === item.membershipId){
                    if(item.membershipAPI === 'resident_and_research_membership'){
                        filesFlag = false;
                        fileErrorMessage += 'an official confirmation/certification of your ongoing training in neurology or PhD studies in English';
                    }else if(item.membershipAPI === 'fellow_membership'){
                        filesFlag = false;
                        fileErrorMessage += 'a cover letter detailing your important achievements and your CV including a list of publications';
                    }else if(item.membershipAPI === 'student_membership'){
                        filesFlag = false;
                        fileErrorMessage += 'a brief explanation of your special interest in neurology and the reason for requesting membership, your CV and student ID';
                    }else if(item.membershipAPI === 'full_membership' || item.membershipAPI === 'corresponding_membership'){
                        filesFlag = false;
                        fileErrorMessage += 'your CV';
                    }
                }
            });
        }
        return {
            filesFlag: filesFlag,
            errorMessage: fileErrorMessage
        };
    }

    handleClickNext() {
        let allFields = this.template.querySelectorAll(".input");
        let isFilled = true;
        allFields.forEach(item => {
            if (!item.reportValidity()) {
                isFilled = false;
            }
        });
        if (!isFilled) {
            this.dispatchToast('Error', 'Please, fill all required fields!', 'error')
        } else if (this.membershipId == null) {
            this.dispatchToast('Error', 'Please, choose membership!', 'error');
        } else if (!this.filesValidation().filesFlag) {
            this.dispatchToast('Error', this.filesValidation().errorMessage, 'error');
        } else if(this.checkRetired()){
            this.dispatchToast('Error', 'You cannot choose retired.  Please ensure that you have entered your correct date of birth and/or date of graduation and licence to practice', 'error');
        } else if(!this.availableMembershipsForApplying.hasOwnProperty(this.membershipId) || !this.availableMembershipsForApplying[this.membershipId]){
            this.dispatchToast('Error', '', 'error');
        } else{
            this.isSpinner = true;
            if (this.formId !== '') {
                this.formValues.Id = this.formId;
            }
            this.formValues.Contact__c = this.currentContactId;
            this.formValues.Membership__c = this.membershipId;
            this.generateOrderWithItems()
                .then(()=>{
                        this.setSelectedValues()
                            .then(()=>{
                                updateContact({contact: this.contact})
                                    .then(()=>{
                                        this.dispatchToast('Success', 'Your personal information updated', 'success');
                                        this.formValues['Order__c'] = this.orderId;
                                        upsertForm({form: this.formValues})
                                            .then(result => {
                                                this.formId = '';
                                                this.formId = result.Id;
                                                this.dispatchToast('Success', 'Form updated', 'success');
                                                this.isShowMemberships = false;
                                                this.validateForm = true;
                                                this.isSpinner = false;
                                                this.manageDisplayPillsSection();
                                                this.attachFilesToAppForm()
                                            })
                                            .catch(error => {
                                                this.dispatchToast('Error', error.body.message, 'error');
                                                this.isSpinner = false;
                                                console.log(JSON.stringify(error));
                                            });
                                    })
                                    .catch(error => {
                                        let message = 'Something went wrong';
                                        if(error.hasOwnProperty('body')) {
                                            if (!error.hasOwnProperty('isUserDefinedException')) {
                                                if (error.body.hasOwnProperty('message')) message = error.body.message;
                                            }
                                        }
                                        console.log('updateContact_ERROR: ' + JSON.stringify(error));
                                        this.dispatchToast('Error', message, 'error');
                                        this.isSpinner = false;
                                    })
                            })
                })
                .catch(error=>{
                    if(error!=null){
                        console.log('this.generateOrderWithItems_ERROR: '+JSON.stringify(error));
                    }
                });
        }
    }

    attachFilesToAppForm(){
        return new Promise((resolve, reject) => {
            let uploadedFilesPills = [...this.uploadedFilesPills];
            let contentDocumentLinks = [];
            uploadedFilesPills.forEach(item => {
                contentDocumentLinks.push({
                    ContentDocumentId: item.documentId,
                    LinkedEntityId: this.formId,
                    ShareType: 'I',
                    Visibility: 'AllUsers',
                });
            });
            attachFileToForm({contentDocumentLinks: contentDocumentLinks})
                .then(() => {
                    resolve();
                }).catch(error => {
                    reject();
                    console.log('error:: ' + JSON.stringify(error));
                    this.dispatchToast('Error', 'Something went wrong with files attachment. Please contact your system administrator.', 'error');
            })
        });
    }

    checkRetired(){
        let errorFlag = false;
        if(this.formValues['Retired__c']) {
            let arr = [];
            arr = this.formValues.hasOwnProperty('Expected_Date_Of_Graduation__c') ? this.formValues['Expected_Date_Of_Graduation__c']!=null?this.formValues['Expected_Date_Of_Graduation__c'].split('-'): ['none'] : ['none'];
            let gradDate = arr[0] === 'none' ? arr[0] : new Date(arr[0], arr[1] - 1, arr[2]);

            arr = this.formValues.hasOwnProperty('License_issued__c') ? this.formValues['License_issued__c']!=null?this.formValues['License_issued__c'].split('-'): ['none'] : ['none'];
            let licDate = arr[0] === 'none' ? arr[0] : new Date(arr[0], arr[1] - 1, arr[2]);

            arr = this.formValues.hasOwnProperty('Date_of_birth__c') ? this.formValues['Date_of_birth__c']!=null?this.formValues['Date_of_birth__c'].split('-'): ['none'] : ['none'];
            let birthDate = arr[0] === 'none' ? arr[0] : new Date(arr[0], arr[1] - 1, arr[2]);

            let dateToday = new Date();
            let sixtyFive = new Date();
            sixtyFive.setFullYear(sixtyFive.getFullYear() - 65);

            if ((gradDate !== 'none' && gradDate > dateToday) || (licDate !== 'none' && licDate > dateToday) || (birthDate === 'none' || birthDate > sixtyFive)) {
                errorFlag = true;
            }
        }
        return errorFlag;
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

    generateOrderItems() {
        let listOrderItems = [];
        let membershipPrice;
        this.radioButtonsLabels.forEach(item => {
            if (item['membershipId'] === this.membershipId) {
                membershipPrice = item['membershipPrice'];
            }
        });
        if (this.membershipId != null && this.membershipId !== '') {
            listOrderItems.push({'Membership__c': this.membershipId, 'Amount__c': membershipPrice, 'Quantity__c': 1});
        }
        this.productOptions.forEach(option => {
            this.selectedProducts.forEach(selected => {
                if (option['value'] === selected) {
                    listOrderItems.push({'Product__c': selected, 'Amount__c': option['price'], 'Quantity__c': 1});
                }
            })
        });
        return listOrderItems;
    }

    setProducts() {
        let productOptions = [];
        let line = 0;
        this.products.forEach(item => {
            if (item.hasOwnProperty('PricebookEntries')) {
                item['PricebookEntries'].forEach(PBEItem => {
                    if (PBEItem['Pricebook2']['Name'] === 'Membership Application') {
                        productOptions.push({
                            label: item['Name'],
                            value: item['Id'],
                            price: PBEItem['UnitPrice'],
                            line: 'checkbox-product ' + line,
                            description: item['Description']
                        });
                    }
                });
            }
            line++;
        });
        if (productOptions.length !== 0) {
            this.isShowProducts = true;
        }
        this.productOptions = [...productOptions];
    }

    catchSelectedProducts() {
        let selectedProducts = [];
        var checkedValues = this.template.querySelectorAll('.checkbox-product:checked');
        checkedValues.forEach(item => {
            if (item.checked) {
                selectedProducts.push(item.value);
            }
        });
        this.selectedProducts = [...selectedProducts];
    }

    handleClickPay() {
        this.isSpinner = true;
        if (!this.filesValidation().filesFlag) {
            this.isSpinner = false;
            this.dispatchToast('Error', this.filesValidation().errorMessage, 'error');
        } else {
            this.attachFilesToAppForm()
                .then(()=>{
                    this.navigateToPaymentPage(this.orderId);
                })
                .catch(()=>{console.log('this.attachFilesToAppForm()_ERROR')})
        }
    }

    generateOrderWithItems(){
        return new Promise((resolve, reject) => {
            if(!this.isEdit){
                generateOrder({ContactId: this.currentContactId, orderItemsObject: this.generateOrderItems(), purchaseType:'New'})
                    .then(orderId => {
                        this.orderId = orderId;
                        resolve();
                    }).catch(error => {
                        this.dispatchToast('Error', error.body.message, 'error');
                        reject();
                    });
            } else {
                updateOrderItems({orderId:this.orderId, orderItems: this.generateOrderItems()})
                    .then(()=>{
                        resolve();
                    })
                    .catch(error=>{
                        console.log('generateOrderWithItems_ERROR: '+JSON.stringify(error));
                        reject();
                    });
            }
        })
    }

    handleClickBack() {
        this.openMembershipInput()
            .then(()=>{
            this.manageDisplayPillsSection();
            this.manageMarkup();
            this.setSelectedMembership();
        })
    }

    setSelectedMembership(){
        if(this.membershipId!=='' || this.membershipId!=null){
            let selectedMembership = this.template.querySelector('input[title="' + this.membershipId + '"]');
            if (selectedMembership != null) {
                selectedMembership.setAttribute('checked', 'checked');
            }
        }
    }

    setSelectedValues() {
        return new Promise((resolve, reject) => {
            let _firstFieldValueSet = [...this.firstFieldValueSet];
            let _secondFieldValueSet = [...this.secondFieldValueSet];
            for (let field in this.formValues) {
                let fieldIsFound = false;
                let item;
                for (let item in _firstFieldValueSet) {
                    if (_firstFieldValueSet[item].field === field) {
                        _firstFieldValueSet[item].value = this.formValues[field];
                        fieldIsFound = true;
                        break;
                    }
                }
                if (!fieldIsFound) {
                    for (item in _secondFieldValueSet) {
                        if (_secondFieldValueSet[item].field === field) {
                            _secondFieldValueSet[item].value = this.formValues[field];
                            break;
                        }
                    }
                }
            }
            this.firstFieldValueSet = [..._firstFieldValueSet];
            this.secondFieldValueSet = [..._secondFieldValueSet];
            resolve();
        });
    }

    openMembershipInput(){
        return new Promise((resolve, reject) => {
            this.validateForm = false;
            this.isShowMemberships = true;
            this.isEdit = true;
            resolve();
        });
    }

    navigateToPaymentPage(orderId) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'payment-component'
            },
            state: {
                orderId: orderId
            }
        });
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
        this.isSpinner = true;
        deleteContentDocumentById({docId:event.detail.item.documentId})
            .then(()=>{
                this.isSpinner = false;
                this.manageDisplayPillsSection();
            })
            .catch(error=>{
                console.log('deleteContentDocumentById_ERROR: '+JSON.stringify(deleteContentDocumentById));
            });
    }

    manageDisplayPillsSection(){
        if(this.uploadedFilesPills.length > 0){
            this.showPillUploadedFiles = true;
        }
        if(this.uploadedFilesPills.length === 0){
            this.showPillUploadedFiles = false;
        }
    }

    manageMarkup() {
        this.setSelectedMembership();

        this.fullMembershipLOGIC();
        this.fellowMembershipLOGIC();
        this.studentMembershipLOGIC();
        this.residentAndResearchMembershipLOGIC();
        this.correspondingIndividualMembershipLOGIC();
        this.manageJournalSection();
    }

    fullMembershipLOGIC() {
        let currentMembership = this.getMembershipByApi('full_membership');
        let htmlMembershipElement = this.template.querySelector('input[title="' + currentMembership.Id + '"]');
        let isFound = false;
        if (htmlMembershipElement != null) {
            this.Country__mdt.forEach(country => {
                if (this.formValues['Profession__c'] === 'Neurologist'){
                    if (country['Country__c'] === this.formValues['Nationality__c'] && country['member_country__c']) {
                        isFound = true;
                    } else if (country['Country__c'] === this.formValues['Residency__c'] && country['member_country__c']) {
                        isFound = true;
                    }
                }
            });
            this.manageMembershipEnabling(isFound, htmlMembershipElement);
        }
        this.availableMembershipsForApplying[currentMembership.Id] = isFound;
    }

    fellowMembershipLOGIC() {
        let currentMembership = this.getMembershipByApi('fellow_membership');
        let htmlMembershipElement = this.template.querySelector('input[title="' + currentMembership.Id + '"]');
        let isFound = false;
        if (htmlMembershipElement != null) {
            this.Country__mdt.forEach(country => {
                if (this.formValues['Profession__c'] === 'Neurologist'){
                    if (country['Country__c'] === this.formValues['Nationality__c'] && country['member_country__c']) {
                        isFound = true;
                    } else if(country['Country__c'] === this.formValues['Residency__c'] && country['member_country__c']){
                        isFound = true;
                    }
                }
            });
            this.manageMembershipEnabling(isFound, htmlMembershipElement);
        }
        this.availableMembershipsForApplying[currentMembership.Id] = isFound;
    }

    residentAndResearchMembershipLOGIC() {
        let currentMembership = this.getMembershipByApi('resident_and_research_membership');
        let isFound = false;
        let htmlMembershipElement = this.template.querySelector('input[title="' + currentMembership.Id + '"]');
        if (htmlMembershipElement != null) {
            if (this.formValues.hasOwnProperty('Profession__c')) {
                if (this.formValues['Profession__c'] === 'Residents/Physician in training'
                    || this.formValues['Profession__c'] === 'Research Fellows in Neurology'
                    || this.formValues['Profession__c'] === 'PhD student in neurology'
                    || this.formValues['Profession__c'] === 'Neurologist') {
                    //AND "I am retired" checkbox not selected
                    if(!this.formValues['Retired__c']){
                        //AND Date conditions
                        let licenseIssued = new Date(Date.parse(this.formValues['License_issued__c']));
                        let gradDate = new Date(Date.parse(this.formValues['Expected_Date_Of_Graduation__c']));
                        let licenseIssuedAdd15Year = new Date(licenseIssued.getFullYear() + 15, licenseIssued.getMonth(), licenseIssued.getDate());
                        let gradDateAdd3Year = new Date(gradDate.getFullYear() + 3, gradDate.getMonth(), gradDate.getDate());
                        let dateToday = new Date().setHours(0,0,0,0);
                        if(licenseIssuedAdd15Year.getTime()>=dateToday && gradDateAdd3Year.getTime()>=dateToday){
                            //AND Date of graduation - License issued <= 15 years
                            let yearsDifference = Math.abs(1970 - new Date(gradDate-licenseIssued).getFullYear());
                            if(yearsDifference<=15){
                                isFound = true;
                            }
                        }
                    }
                }
            }
            this.manageMembershipEnabling(isFound, htmlMembershipElement);
            this.availableMembershipsForApplying[currentMembership.Id] = isFound;
        }
    }

    correspondingIndividualMembershipLOGIC() {
        let currentMembership = this.getMembershipByApi('corresponding_membership');
        let htmlMembershipElement = this.template.querySelector('input[title="' + currentMembership.Id + '"]');
        let isFound = false;
        if (htmlMembershipElement != null) {
            let Country__mdt2 = [...this.Country__mdt];
            for(let country of this.Country__mdt) {
                if (country['Country__c'] === this.formValues['Nationality__c'] && !country['member_country__c'] && this.formValues['Profession__c'] == 'Neurologist') {
                    for(let country2 of this.Country__mdt){
                        if (country2['Country__c'] === this.formValues['Residency__c'] && !country2['member_country__c']) {
                            isFound = true;
                        }
                    }
                } else if (this.formValues['Profession__c'] === 'Other') {
                    isFound = true;
                } else if (this.formValues['Profession__c'] === 'Neurologist working in Pharma') {
                    isFound = true;
                }
            }
            this.manageMembershipEnabling(isFound, htmlMembershipElement);
        }
        this.availableMembershipsForApplying[currentMembership.Id] = isFound;
    }

    studentMembershipLOGIC() {
        let currentMembership = this.getMembershipByApi('student_membership');
        let isFound = false;
        let htmlMembershipElement = this.template.querySelector('input[title="' + currentMembership.Id + '"]');
        if (htmlMembershipElement != null) {
            if (this.formValues.hasOwnProperty('Profession__c')) {
                if (this.formValues.Profession__c.toLowerCase() === 'undergraduate medical student' && !this.formValues['Retired__c'] && Date.parse(this.formValues['Expected_Date_Of_Graduation__c']) >= Date.now()) {
                    isFound = true;
                }
            }
        }
        this.manageMembershipEnabling(isFound, htmlMembershipElement);
        this.availableMembershipsForApplying[currentMembership.Id] = isFound;
    }

    manageMembershipEnabling(isFound, htmlMembershipElement){``
        if (isFound) {
            if (htmlMembershipElement.hasAttribute('disabled')) {
                htmlMembershipElement.removeAttribute('disabled');
            }
        } else {
            if (!htmlMembershipElement.hasAttribute('disabled')) {
                htmlMembershipElement.setAttribute('disabled', 'disabled');
                if(htmlMembershipElement.checked){
                    htmlMembershipElement.checked = false;
                }
            }
        }
    }

    getMembershipByApi(membershipApi) {
        let currentMembership = {};
        this.allAvailableMemberships.forEach(membership => {
            if (membership.API__c === membershipApi) {
                currentMembership = Object.assign({}, membership);
            }
        });
        return currentMembership;
    }

    manageJournalSection(){
        let journalElements = this.template.querySelectorAll('.checkbox-product');
        if(this.selectedProducts.length > 0){
            for(let product of this.selectedProducts){
                for(let element of journalElements){
                    if(product === element.value){
                        element.checked = true;
                    }
                }
            }
        }
    }

    handleClickReSubmit(){
        this.isSpinner = true;
        if (!this.filesValidation().filesFlag) {
            this.isSpinner = false;
            this.dispatchToast('Error', this.filesValidation().errorMessage, 'error');
        } else {
            this.attachFilesToAppForm()
                .then(()=>{
                    submitForApproval({formId: this.formId})
                        .then(()=>{
                            this.dispatchToast('Success', 'Submitted for approval!', 'success');
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: this.formId,
                                    objectApiName: 'Application_form__c',
                                    actionName: 'view'
                                }
                            });
                        })
                        .catch(error=>{console.log('submitForApproval_ERROR: '+JSON.stringify(error))})
                })
                .catch(()=>{console.log('this.attachFilesToAppForm()_ERROR')})
        }
    }
}