import { api } from 'lwc';
import LightningModal from 'lightning/modal';

/** Runs the Upload_Certificate screen flow for a Contact inside a modal. Closes with 'finished' when the flow completes. */
export default class CertificateUploadModal extends LightningModal {
    @api recordId;

    get flowInputs() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.close('finished');
        }
    }
}
