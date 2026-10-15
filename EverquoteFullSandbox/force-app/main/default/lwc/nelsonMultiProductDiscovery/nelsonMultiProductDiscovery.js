import { LightningElement, api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationFinishEvent,
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
    FlowNavigationPauseEvent
} from 'lightning/flowSupport';

export default class NelsonMultiProductDiscovery extends LightningElement {

    @api selectedValue;

    handleNext(event) {
        console.log('button', event.target.label)
        this.selectedValue = event.target.label;
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedValue', this.selectedValue);
        this.dispatchEvent(attributeChangeEvent);

        // Then move to the next screen
        setTimeout(() => {
            const nextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(nextEvent);
        }, 1000);
    }
}