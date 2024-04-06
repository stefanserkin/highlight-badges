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
        return `${this.badge.sObjectType} Details`;
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