import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Utils } from "c/utils";

export default class ErSummarize extends LightningElement {

  @api hideNextButton = false;
  @api hidePreviousButton = false;
  @api nextButtonLabel = "Next";
  @track isSpinner = true;

  connectedCallback() {
    this.isSpinner = false;
  }

  handlePreviousClick() {
    const selectEvent = new CustomEvent("previous", {
      detail: {}
    });
    this.dispatchEvent(selectEvent);
  }

  handleNextClick() {
    const selectEvent = new CustomEvent("continue", {
      detail: {}
    });
    this.dispatchEvent(selectEvent);
  }

  throwError(error) {
    const selectEvent = new CustomEvent("error", {
      detail: error
    });
    this.dispatchEvent(selectEvent);
  }

  dispatchToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }

}