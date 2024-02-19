import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class HighlightBadgesAlertsModal extends LightningModal {
    @api alertsModalHeader;

    handleOkay() {
        this.close('okay');
    }

}