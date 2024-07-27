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
            row.navigationEnabled = (row.sourceRecordId != this.recordId);
            row.hasActions = (row.actions && row.actions.length > 0);
        });
        this._badges = rows;
    }

    maxButtonActions = 1;
    runFlowMode = false;
    flowApiName;
    selectedSourceId;
    includeSourceRecordId = false;
    includeDisplayRecordId = false;

    runFlow(event) {
        this.flowApiName = event.detail.flowApiName;
        this.includeSourceRecordId = event.detail.includeSourceRecordId;
        this.includeDisplayRecordId = event.detail.includeDisplayRecordId;
        this.selectedSourceId = event.target.dataset.sourceId;
        this.runFlowMode = true;
    }

    handleFlowCompletion() {
        this.runFlowMode = false;
        this.dispatchEvent(new CustomEvent('refresh'));
    }

    getHeaderIconStyle(badge) {
        return `--slds-c-icon-color-background: ${badge.backgroundColor}; --slds-c-icon-color-foreground: ${badge.labelColor}`;
    }

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}