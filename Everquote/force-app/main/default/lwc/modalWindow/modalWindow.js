import { LightningElement, api, track } from "lwc";

export default class ModalWindow extends LightningElement {
  @api
  isOpen = false;

  @api
  title = "";
  @api
  content = "";

  decline() {
    this.dispatchCloseEvent(false);
  }

  approve() {
    this.dispatchCloseEvent(true);
  }

  dispatchCloseEvent(approved) {
    const closedEvent = new CustomEvent("modalclosed", { detail: approved });
    this.dispatchEvent(closedEvent);
  }
}