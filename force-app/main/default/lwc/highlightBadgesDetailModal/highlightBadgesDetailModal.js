import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class HighlightBadgesDetailModal extends NavigationMixin(LightningElement) {
    @api badge;
    @api recordId;

    get navigationEnabled() {
        return (this.badge.recordId != this.recordId);
    }

    get fieldSet() {
        let fields = [];
        if (this.badge) {
            fields = this.badge.fieldSet.split(',');
        }
        return fields;
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

    get viewRecordButtonLabel() {
        return `View ${this.badge.sObjectTypeLabel}`;
    }

    handleGoToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.badge.recordId,
                objectApiName: this.badge.sObjectType,
                actionName: 'view'
            }
        });
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}