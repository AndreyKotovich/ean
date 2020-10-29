import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getSoloParticipatCommunityButtonsInitData from "@salesforce/apex/OrderHelper.getSoloParticipatCommunityButtonsInitData";

export default class SoloParticipationCommunityButtons extends NavigationMixin(LightningElement) {
	@api recordId;
	orderId;
	eventId = '';
	displayDoPaymentButton = false;
	displayCancelButton = false;
	displayUpgradeButton = false;
	connectedCallback() {
		console.log('SoloParticipationCommunityButtons connectedCallback');
		console.log('this.recordId: ', this.recordId);
		getSoloParticipatCommunityButtonsInitData({ participantId: this.recordId })
			.then(res => {
				if (res && res.id && res.status) {
					this.orderId = res.id;
					console.log('Paid');
					console.log(res.status === 'Paid');
					//this.displayDoPaymentButton = res.status === 'Paid';
					this.displayDoPaymentButton = res.displayDoPaymentButton;
				}
				this.eventId = res.eventId;
				console.log('this.eventId');
				console.log(this.eventId);
				this.displayCancelButton = res.displayCancelButton;
				this.displayUpgradeButton = res.displayUpgradeButton;

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
		console.log('eventId: ', this.eventId);
		var newURL = window.location.protocol + "//" + window.location.host + "/s/event-registration" + "?ei=" + this.eventId + "&pi=" + this.recordId;
		console.log(newURL);
		window.location.replace(newURL);
		console.log('must redirect');
	}
	handleClickDoPayment() {
		console.log('handleClickDoPayment: this.recordId', this.recordId);
		console.log('handleClickDoPayment: this.orderId', this.recordId);
		if (this.displayDoPaymentButton) {
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