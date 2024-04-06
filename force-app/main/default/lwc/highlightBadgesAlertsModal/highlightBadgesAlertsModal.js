import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class HighlightBadgesAlertsModal extends NavigationMixin(LightningElement) {
    @api modalHeader;
    @api recordId;

    _badges;
    @api
    get badges() {
        return this._badges;
    }
    set badges(value) {
        let rows = JSON.parse( JSON.stringify(value) );
        rows.forEach(row => {
            row.iconStyle = this.getHeaderIconStyle(row);
            row.navigationEnabled = (row.recordId != this.recordId);
            row.viewRecordButtonLabel = this.getViewRecordButtonLabel(row);
        });
        this._badges = rows;
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

    getHeaderIconStyle(badge) {
        return `--slds-c-icon-color-background: ${badge.backgroundColor}; --slds-c-icon-color-foreground: ${badge.labelColor}`;
    }

    getViewRecordButtonLabel(badge) {
        return `View ${badge.sObjectType}`;
    }

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}