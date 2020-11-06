import { LightningElement } from 'lwc';
import getPreparedData from '@salesforce/apex/MembershipRenewalController.getPreparedData';
import recalculateRenewalFee from '@salesforce/apex/MembershipRenewalController.recalculateRenewalFee';
import deleteContentDocumentById from '@salesforce/apex/MembershipRenewalController.deleteContentDocumentById'

export default class MembershipRenewalComponent extends LightningElement {
	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_noRenewalMessage = 'You have no available memberships to renewal.'
	_isSpinner = true;
	_isError = false;

	// _displayMembershipDetails = false;

	_isStep1 = false;
	_isStep2 = false;
	_isStep3 = false;
	_enableNextButtonStep1 = false;
	_enableNextButtonStep2 = false;
	_enableNextButtonStep3 = false;

	_currentContactId = '';
	_membershipId = '';
	_membershipName = '';
	_membershipStatusId = '';
	_applicationFormId = '';
	_totalRenewalFee = 0;

	//	EANMR-2, EANMR-5	//	STEP 1
	_formSalutation = '--None--';
	_formFirstName = '';
	_formLastName = '';
	_formPostNominalTitle = '';
	_formDateOfBirth;
	_formGender = '--None--';
	_formEmail = '';
	_formNationality = '';
	_formCountryOfResidence = '';
	_formStreet = '';
	_formZipPostalCode = '';
	_formCity = '';
	_formPhoneNumber = '';

	_enableEditFromDateOfBirth = false;
	_availableSalutations = [];				//	picklist
	_availableGenders = [];					//	picklist
	_availableNationalities = [];			//	picklist
	_availableCountryOfResidences = [];		//	picklist

	//	EANMR-15, EANMR-16	// STEP 2
	_enableGraduationAndLicenseStep = false;
	_minimumDateOfGraduation;
	_dateOfGraduation;
	_licenseIssuedDate;
	_displayDateOfGraduation = false;
	_displayLicenseIssued = false;

	_uploadedFilesPills = [];
	_showPillUploadedFiles = false;


	renderedCallback() {
		// if (this._displayMembershipDetails && this._enableNextButtonStep1) this.template.querySelector('button[name="button-next-step-one"]').removeAttribute('disabled');
		if (this._isStep1 && this._enableNextButtonStep1) this.template.querySelector('button[name="button-next-step-one"]').removeAttribute('disabled');
	}

	connectedCallback() {
		console.log('MembershipRenewalComponent connectedCallback');
		this._isSpinner = true;
		// this._displayMembershipDetails = false;
		this._isStep1 = false;

		getPreparedData().then(result=>{
				console.log('result: ', result);
				this._isSpinner = false;

				if (!result.result) {
					this._isError = true;
					return;
				}

				this._isError = false;
				// this._displayMembershipDetails = true;
				this._isStep1 = true;

				this._currentContactId = result.currentContactId;
				this._membershipId = result.membershipId;
				this._membershipName = result.membershipName;
				this._membershipStatusId = result.membershipStatusId;
				this._applicationFormId = result.applicationFormId;
				this._totalRenewalFee = result.totalRenewalFee;

				//	EANMR-2, EANMR-5	//	STEP 1
				this._formSalutation = result.formSalutation;
				this._formFirstName = result.formFirstName;
				this._formLastName = result.formLastName;
				this._formPostNominalTitle = result.formPostNominalTitle;
				this._formDateOfBirth = result.formDateOfBirth;
				this._formGender = result.formGender;
				this._formEmail = result.formEmail;
				this._formNationality = result.formNationality;
				this._formCountryOfResidence = result.formCountryOfResidence;
				this._formStreet = result.formStreet;
				this._formZipPostalCode = result.formZipPostalCode;
				this._formCity = result.formCity;
				this._formPhoneNumber = result.formPhoneNumber;

				this._enableEditFromDateOfBirth = result.enableEditFromDateOfBirth;
				this._enableNextButtonStep1 = result.enableNextButtonStep1;

				var salutationsListMap = result.availableSalutations;
				this._availableSalutations.push({label: '--None--', value: '--None--'});
				for (var i = 0 ; i < salutationsListMap.length ; i++) {
					this._availableSalutations.push({label: salutationsListMap[i].label, value: salutationsListMap[i].value});
				}

				var gendersListMap = result.availableGenders;
				this._availableGenders.push({label: '--None--', value: '--None--'});
				for (var i = 0 ; i < gendersListMap.length ; i++) {
					this._availableGenders.push({label: gendersListMap[i].label, value: gendersListMap[i].value});
				}

				var nationalitiesListMap = result.availableNationalities;
				for (var i = 0 ; i < nationalitiesListMap.length ; i++) {
					this._availableNationalities.push({label: nationalitiesListMap[i].label, value: nationalitiesListMap[i].value});
				}

				var countryOfResidencesListMap = result.availableCountryOfResidences;
				for (var i = 0 ; i < countryOfResidencesListMap.length ; i++) {
					this._availableCountryOfResidences.push({label: countryOfResidencesListMap[i].label, value: countryOfResidencesListMap[i].value});
				}

				//	EANMR-15, EANMR-16	// STEP 2
				this._enableGraduationAndLicenseStep = result.enableGraduationAndLicenseStep;
				this._minimumDateOfGraduation = result.minimumDateOfGraduation;
				this._dateOfGraduation = result.dateOfGraduation;
				this._licenseIssuedDate = result.licenseIssuedDate;
				this._displayDateOfGraduation = result.displayDateOfGraduation;
				this._displayLicenseIssued = result.displayLicenseIssued;

				this.validateEnableNextButtonStep1();

			})
			.catch(error=>{
				console.log('MembershipRenewalComponent error: ', error);
				console.log('connectedCallback Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
			})
	}

	handleChangeSalutation(event) {
		this._formSalutation = event.detail.value;
		this.validateEnableNextButtonStep1();
	}

	//	disabled
	handleChangeFirstName(event) {
		this._formFirstName = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	//	disabled
	handleChangeLastName(event) {
		this._formLastName = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	handleChangeTitle(event) {
		this._formPostNominalTitle = event.target.value;
		this.validateEnableNextButtonStep1();
	}
	
	handleChangeDateOfBirth(event) {
		this._formDateOfBirth = event.target.value;
		this.validateEnableNextButtonStep1();
	}
	
	handleChangeGender(event) {
		this._formGender = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	handleChangeEmail(event) {
		this._formEmail = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	handleChangeNationality(event) {
		this._formNationality = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	handleChangeCountry(event) {
		console.log('handleChangeCountry 1');
		this._enableNextButtonStep1 = false;
		this._formCountryOfResidence = event.target.value;
		this.template.querySelector('button[name="button-next-step-one"]').setAttribute('disabled');
		this._isSpinner = true;

		recalculateRenewalFee({params: {
			membershipId: this._membershipId,
			formCountryOfResidence: this._formCountryOfResidence
			}}).then(result=>{
				this._isSpinner = false;

				if (!result.result) {
					console.log('result: ', result);
					this._isError = true;
					this._enableNextButtonStep1 = false;
					return;
				}

				this._isError = false;
				this._enableNextButtonStep1 = true;
				this._totalRenewalFee = result.totalRenewalFee;
				this.validateEnableNextButtonStep1();
			})
			.catch(error=>{
				console.log('MembershipRenewalComponent error: ', error);
				console.log('handleChangeCountry Error: ' + JSON.stringify(error));
				this._isError = true;
				this._isSpinner = false;
				this._enableNextButtonStep1 = false;
			})

	}

	handleChangeStreet(event) {
		this._formStreet = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	handleChangeZipPostalCode(event) {
		this._formZipPostalCode = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	handleChangeCity(event) {
		this._formCity = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	handleChangePhone(event) {
		this._formPhoneNumber = event.target.value;
		this.validateEnableNextButtonStep1();
	}

	handleClickSubmit() {
		console.log('handleClickSubmit 1');
	}

	validateEnableNextButtonStep1() {
		console.log('validateEnableNextButtonStep1');

		// console.log('this._formSalutation: ', this._formSalutation);
		// console.log('this._formFirstName: ', this._formFirstName);
		// console.log('this._formLastName: ', this._formLastName);
		// console.log('this._formDateOfBirth: ', this._formDateOfBirth);
		// console.log('this._formGender: ', this._formGender);
		// console.log('this._formEmail: ', this._formEmail);
		// console.log('this._formNationality: ', this._formNationality);
		// console.log('this._formCountryOfResidence: ', this._formCountryOfResidence);
		// console.log('this._formStreet: ', this._formZipPostalCode);
		// console.log('this._formZipPostalCode: ', this._formCity);
		// console.log('this._formCity: ', this._formCity);

		if (!this._isError
			&& this._formFirstName.length > 0
			&& this._formLastName.length > 0
			&& this._formDateOfBirth
			&& this._formGender !== '--None--'
			&& this._formEmail.length > 0
			&& this._formNationality.length > 0
			&& this._formCountryOfResidence.length > 0
			&& this._formStreet.length > 0
			&& this._formZipPostalCode.length > 0
			&& this._formCity.length > 0) {

			this._enableNextButtonStep1 = true;
			// this.template.querySelector('button[name="button-next-step-one"]').removeAttribute('disabled');
			return;
		}

		this._enableNextButtonStep1 = false;
		this.template.querySelector('button[name="button-next-step-one"]').setAttribute('disabled');

	}

	handleClickNextButtonStep1() {
		console.log('handleClickNextButtonStep1');
		if (this._enableNextButtonStep1 == false) return;

		console.log('handleClickNextButtonStep2');
		this._isStep1 = false;
		if (this._enableGraduationAndLicenseStep == true) {
			this._isStep2 = true;
		} else {
			this._isStep3 = true;
		}

		console.log('this._isStep1: ', this._isStep1);
		console.log('this._isStep2: ', this._isStep2);
		console.log('this._isStep3: ', this._isStep3);

	}


	//	STEP 2
	get acceptedFormats() {
		return ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
	}

	handleUploadFinished(event) {
		console.log('handleUploadFinished 1');
		const uploadedFiles = event.detail.files;
		let uploadedFilesPills = [...this._uploadedFilesPills];
		uploadedFiles.forEach(item=>{
			uploadedFilesPills.push({
				type: 'icon',
				label: item.name,
				iconName: 'doctype:attachment',
				documentId: item.documentId,
			});
		});
		this._uploadedFilesPills = [...uploadedFilesPills];
		this.manageDisplayPillsSection();
		console.log('handleUploadFinished 2');
	}

	handleRemoveFilePill(event){
		console.log('handleRemoveFilePill 1');
		const index = event.detail.index;
		this._uploadedFilesPills.splice(index, 1);
		this._uploadedFilesPills = [...this._uploadedFilesPills];
		deleteContentDocumentById({recordId: event.detail.item.documentId});
		this.manageDisplayPillsSection();
		console.log('handleRemoveFilePill 2');
	}

	manageDisplayPillsSection(){
		this._showPillUploadedFiles = this._uploadedFilesPills.length > 0;
	}


}