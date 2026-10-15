import { LightningElement, api } from 'lwc';

/**
 * A reusable alert message component that dynamically changes its appearance 
 * based on the 'type' property (error, warning, success, info).
 */
export default class CustomAlertMessage extends LightningElement {
    // Public API properties exposed to the Lightning App Builder
    @api message = 'This is a dynamic alert message.';
    @api type = 'info'; // Default type is info

    /**
     * Computed property to determine the main alert container classes.
     * Uses SLDS themes to control color:
     * - error: Red
     * - warning: Yellow/Orange
     * - success: Green
     * - info: Blue/Neutral (Standard SLDS info theme)
     */
    get alertContainerClass() {
        // IMPORTANT FIX: Removed 'slds-m-around_medium' and 'slds-box slds-box_small'.
        // These classes often caused horizontal overflow when the component was placed in a full-width record page column.
        // We now rely on the standard SLDS notify classes and small padding.
        const baseClass = 'slds-notify slds-notify_alert slds-theme_alert-texture slds-p-around_small';
        
        switch (this.type.toLowerCase()) {
            case 'error':
                return `${baseClass} slds-theme_error`; // Red for Error
            case 'warning':
                return `${baseClass} slds-theme_warning`; // Orange/Yellow for Warning
            case 'success':
                return `${baseClass} slds-theme_success`; // Green for Success
            case 'info':
                return `${baseClass} slds-theme_info`; // Standard Info (Light Blue/Gray)
            default:
                return `${baseClass} slds-theme_default`; // Default/Gray
        }
    }

    /**
     * Computed property to select the appropriate SLDS icon name (utility scope).
     */
    get iconName() {
        switch (this.type.toLowerCase()) {
            case 'error':
                return 'utility:error';
            case 'warning':
                return 'utility:warning';
            case 'success':
                return 'utility:success';
            case 'info':
                return 'utility:info';
            default:
                return 'utility:notification';
        }
    }

    /**
     * Computed property to determine the icon variant. 
     * 'inverse' gives a white icon on a colored background (Error/Success), 
     * 'warning' gives a colored icon (Warning/Info).
     */
    get iconVariant() {
        switch (this.type.toLowerCase()) {
            case 'error':
            case 'success':
                // Use inverse variant for red and green themes to ensure contrast
                return 'inverse';
            case 'warning':
                // Warning theme handles its own icon color well
                return 'warning'; 
            case 'info':
                // Info theme handles its own icon color well
                return 'info';
            default:
                return '';
        }
    }
}