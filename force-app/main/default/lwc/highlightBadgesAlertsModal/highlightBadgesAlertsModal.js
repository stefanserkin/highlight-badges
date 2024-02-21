import { LightningElement, api } from 'lwc';

export default class HighlightBadgesAlertsModal extends LightningElement {
    @api modalHeader;
    @api alertMessages;
    showCancel = false;
    showOkay = true;

    handleCloseEvent() {
        console.log('doing this close thing');
        this.dispatchEvent(new CustomEvent('close'));
    }

}