import { LightningElement, api } from 'lwc';

export default class SoloParticipationCommunityButtons extends LightningElement {
	@api recordId;

	connectedCallback() {
		console.log('SoloParticipationCommunityButtons connectedCallback');
		console.log('this.recordId: ', this.recordId);
	}

	handleClickCancel() {
		console.log('handleClickCancel: ', this.recordId);
	}
	handleClickUpgrade() {
		console.log('handleClickUpgrade: ', this.recordId);
	}
	handleClickDoPayment() {
		console.log('handleClickDoPayment: ', this.recordId);
	}
}