import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class HighlightBadgeDefinitionCreatorModal extends LightningModal {

    handleSuccess(event) {
        const recordId = event.detail.recordId;
        this.close(recordId);
    }

    handleCancel() {
        this.close('back');
    }

}