import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class HighlightBadgeDefinitionCreatorModal extends LightningModal {

    handleSuccess(event) {
        console.log(event);
        const recordId = event.detail.recordId;
        console.log(':::: recordId --> ' + recordId);
        this.close(recordId);
    }

    handleCancel() {
        this.close('back');
    }

}