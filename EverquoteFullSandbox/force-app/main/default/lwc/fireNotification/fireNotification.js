import { ShowToastEvent } from "lightning/platformShowToastEvent";

const fireLoadNotification = (context, isLoading, bubbles = false, composed = false) => {
  context.dispatchEvent(
    new CustomEvent("loadnotification", {
      detail: {
        isLoading: isLoading
      },
      bubbles: bubbles,
      composed: composed
    })
  );
};

const showToastNotification = (context, title, message, variant) => {
  const event = new ShowToastEvent({
    title: title,
    message: message,
    variant: variant,
    mode: "sticky"
  });
  context.dispatchEvent(event);
};

const toastVariant = {
  error: "error",
  warning: "warning",
  success: "success",
  info: "info"
};

export { fireLoadNotification, showToastNotification, toastVariant };