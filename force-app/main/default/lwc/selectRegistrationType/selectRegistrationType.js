import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Utils } from "c/utils";

export default class SelectRegistrationType extends LightningElement {
  //TODO Only contacts of Industry Partner accounts can start an Industry Partner Registration (IPR)
  @api hideNextButton = false;
  @api hidePreviousButton = false;
  @api nextButtonLabel = "Next";

  @api
  get registrationType() {
    return this._selectedRegistrationType;
  }

  set registrationType(value) {
    this._selectedRegistrationType = value;
  }

  @api get groupName() {
    return this._groupName;
  }

  set groupName(value) {
    this._groupName = value;
  }

  @track isSpinner = true;

  registrationTypes = [
    {
      label: "Solo registration",
      value: "solo"
    },
    {
      label: "Group registration",
      value: "group"
    },
    {
      label: "IPR registration",
      value: "ipr"
    }
  ];
  _selectedRegistrationType = "";
  _groupName = "";

  connectedCallback() {
    this.isSpinner = false;
    this.defineGroupName();
  }

  handlePreviousClick() {
    const selectEvent = new CustomEvent("previous", {
      detail: {}
    });
    this.dispatchEvent(selectEvent);
  }

  handleNextClick() {
    if (
      Utils.validateElements.call(this, "lightning-combobox, lightning-input")
    ) {
      const selectEvent = new CustomEvent("continue", {
        detail: {
          registrationType: this._selectedRegistrationType,
          groupName: this.isGroupRegistration ? this._groupName : ""
        }
      });
      this.dispatchEvent(selectEvent);
    }
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

  handleSelectType(event) {
    this._selectedRegistrationType = event.detail.value;
    this.defineGroupName();
  }

  handleSelectGroupName(event) {
    this._groupName = event.detail.value;
  }

  get isGroupRegistration() {
    return this._selectedRegistrationType !== "solo";
  }

  defineGroupName() {
    if (this.isGroupRegistration && this._groupName === "") {
      let urlParams = new URL(window.location);
      this._groupName = !!!urlParams.searchParams.get("gn")
        ? ""
        : urlParams.searchParams.get("gn");
    }
  }
}