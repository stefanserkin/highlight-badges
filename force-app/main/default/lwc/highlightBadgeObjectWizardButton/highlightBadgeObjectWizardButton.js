import { LightningElement, api } from 'lwc';

export default class HighlightBadgeObjectWizardButton extends LightningElement {
    @api recordId;
    showModal = false;

    handleOpenModal() {
        this.showModal = true;
    }

    handleCloseModal() {
        this.showModal = false;
    }
}