import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class HighlightBadgesDetailModal extends NavigationMixin(LightningElement) {
    @api badge;
    @api recordId;

    maxButtonActions = 3;

    runFlowMode = false;
    flowApiName;
    includeRecordId = false;
    includeDisplayRecordId = false;

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
        this.includeRecordId = event.detail.includeRecordId;
        this.includeDisplayRecordId = event.detail.includeDisplayRecordId;
        this.runFlowMode = true;
    }

    handleFlowCompletion() {
        this.runFlowMode = false;
        this.dispatchEvent(new CustomEvent('refresh'));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}