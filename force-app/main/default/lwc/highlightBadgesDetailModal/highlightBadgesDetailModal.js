import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

export default class HighlightBadgesDetailModal extends NavigationMixin(LightningElement) {
    @api badge;
    @api badgeId;
    @api recordId;

    maxButtonActions = 3;

    runFlowMode = false;
    flowApiName;
    includeSourceRecordId = false;
    includeDisplayRecordId = false;

    get badgeSourceRecordId() {
        return this.badge ? this.badge.sourceRecordId : null;
    }

    get fieldsToDisplay() {
        // Ensure the badge and its sObjectType are defined before attempting to format field names
        if (this.badge && this.badge.sObjectType && this.badge.fieldSet) {
            return this.badge.fieldSet.split(',')
                .map(field => `${this.badge.sObjectType}.${field.trim()}`);
        }
        return [];
    }

    /**
     * Use getRecord so that the record-view-form can be refreshed
     * when a child action is completed that could alter record data
     */
    @wire(getRecord, { recordId: '$badgeSourceRecordId', fields: '$fieldsToDisplay' })
    wiredRecord;

    get fieldSet() {
        let fields = [];
        if (this.badge) {
            fields = this.badge.fieldSet.split(',');
        }
        return fields;
    }

    get hasActions() {
        return this.badge && this.badge.actions && this.badge.actions.length > 0;
    }

    get hasAlert() {
        return this.badge.hasAlert && this.badge.alertMessage;
    }

    get detailsHeader() {
        return `${this.badge.sObjectTypeLabel} Details`;
    }

    get headerStyle() {
        return `background-color: ${this.badge.backgroundColor}; padding: 1rem; width: 100%;`;
    }

    get headerIconStyle() {
        return `--slds-c-icon-color-background: ${this.badge.backgroundColor}; --slds-c-icon-color-foreground: ${this.badge.labelColor}`;
    }

    get headerTextStyle() {
        return `color: ${this.badge.labelColor};`;
    }

    runFlow(event) {
        this.flowApiName = event.detail.flowApiName;
        this.includeSourceRecordId = event.detail.includeSourceRecordId;
        this.includeDisplayRecordId = event.detail.includeDisplayRecordId;
        this.runFlowMode = true;
    }

    handleFlowCompletion() {
        this.runFlowMode = false;
        this.dispatchEvent(new CustomEvent('refresh'));
        refreshApex(this.wiredRecord);
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}