import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getOrderIdFromParticipant from "@salesforce/apex/OrderHelper.getOrderIdFromParticipant";

export default class SoloParticipationCommunityButtons extends NavigationMixin(LightningElement) {
	@api recordId;
	orderId;
	isDoPayment = false;
	connectedCallback() {
		console.log('SoloParticipationCommunityButtons connectedCallback');
		console.log('this.recordId: ', this.recordId);
		getOrderIdFromParticipant({ participantId: this.recordId })
			.then(res => {
				if (res && res.id) {
					this.orderId = res.id;
					this.isDoPayment = res.status === 'Paid';
				}
			})
			.catch(error => {
				console.log('getOrderIdFromParticipant error', error);
			});
	}

	handleClickCancel() {
		console.log('handleClickCancel: ', this.recordId);
	}
	handleClickUpgrade() {
		console.log('handleClickUpgrade: ', this.recordId);
	}
	handleClickDoPayment() {
		console.log('handleClickDoPayment: this.recordId', this.recordId);
		console.log('handleClickDoPayment: this.orderId', this.recordId);
		if (this.isDoPayment) {
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'payment-component'
				},
				state: {
					orderId: this.orderId
				}
			});
		}
	}
}