import { LightningElement } from 'lwc';
import getPreparedData from '@salesforce/apex/MembershipRenewalController.getPreparedData';
import recalculateRenewalFee from '@salesforce/apex/MembershipRenewalController.recalculateRenewalFee';
import deleteContentDocumentById from '@salesforce/apex/MembershipRenewalController.deleteContentDocumentById'

export default class MembershipRenewalComponent extends LightningElement {
	_errorMessage = 'Something went wrong, please contact your system administrator.';
	_noRenewalMessage = 'You have no available memberships to renewal.'
	_isSpinner = true;
	_isError = false;

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
	_membershipRegion = '';
	_membershipURL = '';
	_applicationFormId = '';
	_renewalFee = 0;
	_totalRenewalFee = 0;	//	with 'I am AAN Member' and 'I am Retired' discounts
	_currentYearString = '';
	_nextYearString = '';
	_communityUpdateUrl = '';

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
	_formIamAANMember = false;
	_formIamRetired = false;
	_formProfession = '';

	_allowAANMemberDiscount = false;
	_allowRetiredDiscount = false;

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

	_isValidDateOfGraduation = false;
	_dateOfGraduationErrorMessage = 'Will Be Defined In Callback';

	_displayDateOfGraduationUpdateMessage = false;


	_uploadedFilesPills = [];
	_showPillUploadedFiles = false;

	//	STEP 3
	_selectedJournals = [];
	_agreeToEANTerms = false;
	_displayDevelopToPaymentProcessBlock = false;	//	DEVELOP MOMENT

	renderedCallback() {
		// this.validateEnableNextButtonStep1();
		if (this._isStep1) this.validateEnableNextButtonStep1();
		if (this._isStep1 && this._enableNextButtonStep1) this.template.querySelector('button[name="button-next-step-one"]').removeAttribute('disabled');
		if (this._isStep2 && this._enableNextButtonStep2) this.template.querySelector('button[name="button-next-step-two"]').removeAttribute('disabled');
		if (this._isStep2) this.validateEnableNextButtonStep2();
		if (this._isStep3 && this._enableNextButtonStep3) this.template.querySelector('button[name="button-next-step-three"]').removeAttribute('disabled');
	}

	connectedCallback() {
		this._isSpinner = true;
		this._isStep1 = false;

		getPreparedData().then(result=>{
				console.log('result: ', result);
				this._isSpinner = false;

				if (!result.result) {
					this._isError = true;
					return;
				}

				this._isError = false;
				this._isStep1 = true;

				this._currentContactId = result.currentContactId;
				this._membershipId = result.membershipId;
				this._membershipName = result.membershipName;
				this._membershipStatusId = result.membershipStatusId;
				this._membershipRegion = result.membershipRegion;
				this._membershipURL = result.membershipURL;
				this._applicationFormId = result.applicationFormId;
				this._renewalFee = result.renewalFee;
				this._totalRenewalFee = result.renewalFee;
				this._currentYearString = result.currentYearString;
				this._nextYearString = result.nextYearString;
				this._communityUpdateUrl = result.communityHomeUrl + '/s/membership-application?re=' + this._membershipStatusId;

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
				this._formIamAANMember = result.formIamAANMember;
				this._formIamRetired = result.formIamRetired;
				this._formProfession = result.formProfession;

				this._allowAANMemberDiscount = result.allowAANMemberDiscount;
				this._allowRetiredDiscount = result.allowRetiredDiscount;

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

				this._dateOfGraduationErrorMessage = this._membershipName === 'Resident and Research Membership'
					? 'Will be defined by EAN! (validation 3 years)'
						: 'If you have already graduated, you are no longer eligible for student Membership. Please proceed to upgrade your Membership. (validation future)';

				this.applyAANandRetiredDiscounts();

				//	DEVELOP MOMENT
				// this._isStep1 = false;
				// this._isStep2 = false;
				// this._isStep3 = true;
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

	handleChangeIamAANMember(event) {
		this._formIamAANMember = event.target.checked;
		this.applyAANandRetiredDiscounts();
		this.validateEnableNextButtonStep1();
	}

	handleChangeIamRetired(event) {
		this._formIamRetired = event.target.checked;
		this.applyAANandRetiredDiscounts();
		this.validateEnableNextButtonStep1();
	}

	handleChangeCountry(event) {
		this._enableNextButtonStep1 = false;
		this._formCountryOfResidence = event.target.value;
		this.template.querySelector('button[name="button-next-step-one"]').setAttribute('disabled');
		this._isSpinner = true;

		recalculateRenewalFee({params: {
			membershipId: this._membershipId,
			membershipName: this._membershipName,
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
				this._renewalFee = result.renewalFee;
				this._totalRenewalFee = result.renewalFee;
				this._allowAANMemberDiscount = result.allowAANMemberDiscount;
				this._allowRetiredDiscount = result.allowRetiredDiscount;
				this.applyAANandRetiredDiscounts();
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

	applyAANandRetiredDiscounts() {
		console.log('applyAANandRetiredDiscounts');
		let discountMultiplier = 1;
		if (this._formIamAANMember && this._allowAANMemberDiscount) discountMultiplier = discountMultiplier - 0.1;
		if (this._formIamRetired && this._allowRetiredDiscount) discountMultiplier = discountMultiplier - 0.5;
		this._totalRenewalFee = this._renewalFee * discountMultiplier;
	}


	validateEnableNextButtonStep1() {
		this.setCustomValidityStep1();
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
			&& this._formCity.length > 0
			&& this._renewalFee !== 9999
			&& this._totalRenewalFee !== 9999
		) {
			this._enableNextButtonStep1 = true;
			return;
		}

		this._enableNextButtonStep1 = false;
		let buttonNextStepOne = this.template.querySelector('button[name="button-next-step-one"]');
		if (buttonNextStepOne) buttonNextStepOne.setAttribute('disabled');
	}

	setCustomValidityStep1() {
		if (this._isError || !this._isStep1) return;

		let dateOfBirth1 = this.template.querySelector('[data-id="form-date-of-birth-a"]');
		let dateOfBirth2 = this.template.querySelector('[data-id="form-date-of-birth-b"]');
		let gender = this.template.querySelector('[data-id="form-gender"]');
		let email = this.template.querySelector('[data-id="form-email"]');
		let nationality = this.template.querySelector('[data-id="form-nationality"]');
		let country = this.template.querySelector('[data-id="form-country"]');
		let street = this.template.querySelector('[data-id="form-street"]');
		let zipPostalCode = this.template.querySelector('[data-id="form-zip-postal-code"]');
		let city = this.template.querySelector('[data-id="form-city"]');
		if ((!dateOfBirth1 && !dateOfBirth2) || !gender || !email || !nationality || !country || !street || !zipPostalCode || !city) return;

		if (dateOfBirth1) {
			if (this._formDateOfBirth) { dateOfBirth1.setCustomValidity(''); } else { dateOfBirth1.setCustomValidity('Complete this field.'); }
		}
		if (this._formGender !== '--None--') { gender.setCustomValidity(''); } else { gender.setCustomValidity('Complete this field.'); }
		if (this._formEmail.length > 0) { email.setCustomValidity(''); } else { email.setCustomValidity('Complete this field.'); }
		if (this._formNationality.length > 0) { nationality.setCustomValidity(''); } else { nationality.setCustomValidity('Complete this field.'); }
		if (this._formCountryOfResidence.length > 0) { country.setCustomValidity(''); } else { country.setCustomValidity('Complete this field.'); }
		if (this._formStreet.length > 0) { street.setCustomValidity(''); } else { street.setCustomValidity('Complete this field.'); }
		if (this._formZipPostalCode.length > 0) { zipPostalCode.setCustomValidity(''); } else { zipPostalCode.setCustomValidity('Complete this field.'); }
		if (this._formCity.length > 0) { city.setCustomValidity(''); } else { city.setCustomValidity('Complete this field.'); }

		if (dateOfBirth1) { dateOfBirth1.reportValidity(); }
		gender.reportValidity();
		email.reportValidity();
		nationality.reportValidity();
		country.reportValidity();
		street.reportValidity();
		zipPostalCode.reportValidity();
		city.reportValidity();
	}


	handleClickNextButtonStep1() {
		if (this._enableNextButtonStep1 == false) return;
		this._isStep1 = false;
		if (this._enableGraduationAndLicenseStep == true) {
			this._isStep2 = true;
		} else {
			this._isStep3 = true;
		}
	}


	//	STEP 2
	get acceptedFormats() {
		return ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
	}

	handleChangeDateOfGraduation(event) {
		this._dateOfGraduation = event.target.value;
		this.validateEnableNextButtonStep2();
	}

	handleChangeLicenseIssued(event) {
		this._licenseIssuedDate = event.target.value;
		this.validateEnableNextButtonStep2();
	}

	handleUploadFinished(event) {
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
	}

	handleRemoveFilePill(event){
		const index = event.detail.index;
		this._uploadedFilesPills.splice(index, 1);
		this._uploadedFilesPills = [...this._uploadedFilesPills];
		deleteContentDocumentById({recordId: event.detail.item.documentId});
		this.manageDisplayPillsSection();
	}

	manageDisplayPillsSection(){
		this._showPillUploadedFiles = this._uploadedFilesPills.length > 0;
		this.validateEnableNextButtonStep2();
	}

	validateEnableNextButtonStep2() {
		this.validateLicenseIssued();
		this.validateDateOfGraduation();
		if (!this._isError
			&& this._isValidDateOfGraduation
			// && (!this._displayDateOfGraduation || (this._dateOfGraduation && this._dateOfGraduation >= this._minimumDateOfGraduation))
			// && (!this._displayDateOfGraduation || this._dateOfGraduation)
			&& (!this._displayLicenseIssued || this._licenseIssuedDate)
			&& this._showPillUploadedFiles) {

			this._enableNextButtonStep2 = true;
			return;
		}

		this._enableNextButtonStep2 = false;
		let buttonNextStepTwo = this.template.querySelector('button[name="button-next-step-two"]');
		if (buttonNextStepTwo) buttonNextStepTwo.setAttribute('disabled');
	}

	validateLicenseIssued() {
		if (!this._displayLicenseIssued) return;

		let licenseIssuedDate = this.template.querySelector('.licenseIssuedDate');
		let customValidityMessage = '';
		if (!this._licenseIssuedDate) customValidityMessage = 'Complete this field.';
		if (licenseIssuedDate) {
			licenseIssuedDate.setCustomValidity(customValidityMessage);
			licenseIssuedDate.reportValidity();
		}
	}

	validateDateOfGraduation() {
		if (!this._displayDateOfGraduation) {
			this._isValidDateOfGraduation = true;
			return;
		}

		let dateOfGraduation = this.template.querySelector('.dateOfGraduation');
		this._isValidDateOfGraduation = true;
		let customValidityMessage = '';

		if (this._dateOfGraduation && this._dateOfGraduation < this._minimumDateOfGraduation) customValidityMessage = this._dateOfGraduationErrorMessage;

		// if (customValidityMessage !== '') { this._displayDateOfGraduationUpdateMessage = true; } else { this._displayDateOfGraduationUpdateMessage = false; }
		this._displayDateOfGraduationUpdateMessage = customValidityMessage !== '';

		if (!this._dateOfGraduation) customValidityMessage = 'Complete this field.';
		if (customValidityMessage !== '') this._isValidDateOfGraduation = false;
		if (dateOfGraduation) {
			dateOfGraduation.setCustomValidity(customValidityMessage);
			dateOfGraduation.reportValidity();
		}
	}

	handleClickPrevButtonStep2() {
		this._isStep1 = true;
		this._isStep2 = false;
		this._isStep3 = false;
	}

	handleClickNextButtonStep2() {
		if (this._enableNextButtonStep2 == false) return;
		this._isStep1 = false;
		this._isStep2 = false;
		this._isStep3 = true;
	}

    handleJournalSelect(event){
		let journals = event.detail.selectedProducts;
		console.log('handleJournalSelect journals: ', journals);

		let selectedJournals = [];
		for (let journal of journals) {
			selectedJournals.push({journalProductId: journal.productId, journalPrice: journal.price});
		}
		this._selectedJournals = selectedJournals;
		console.log('handleJournalSelect this._selectedJournals: ', this._selectedJournals);
    }


	handleClickPrevButtonStep3() {
		this._isStep2 = true;
		this._isStep3 = false;

		this._displayDevelopToPaymentProcessBlock = false;	//	DEVELOP MOMENT
	}

	handleChangeEANTerms(event) {
		this._agreeToEANTerms = event.target.checked;
		this._enableNextButtonStep3 = this._agreeToEANTerms;
		this.validateEnableNextButtonStep3();
	}

	validateEnableNextButtonStep3() {
		if (this._enableNextButtonStep3) return;
		let buttonNextStepThree = this.template.querySelector('button[name="button-next-step-three"]');
		if (buttonNextStepThree) buttonNextStepThree.setAttribute('disabled');
	}

	handleClickNextButtonStep3() {
		if (this._enableNextButtonStep3 == false) return;
		this._displayDevelopToPaymentProcessBlock = true;	//	DEVELOP MOMENT
	}

}