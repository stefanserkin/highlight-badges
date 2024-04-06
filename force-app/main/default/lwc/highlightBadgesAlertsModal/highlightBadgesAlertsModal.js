import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class HighlightBadgesAlertsModal extends NavigationMixin(LightningElement) {
    @api modalHeader;
    @api badges;

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleGoToRecord(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selectedBadge = this.badges.find(badge => {
            return badge.id === selectedId
        });

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: selectedBadge.recordId,
                objectApiName: selectedBadge.sObjectType,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

}