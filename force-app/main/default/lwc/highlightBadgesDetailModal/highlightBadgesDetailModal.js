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