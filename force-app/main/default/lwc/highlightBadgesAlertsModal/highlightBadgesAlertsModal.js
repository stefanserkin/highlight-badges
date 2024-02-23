import { LightningElement, api } from 'lwc';

export default class HighlightBadgesAlertsModal extends LightningElement {
    @api modalHeader;
    @api alertMessages;

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}