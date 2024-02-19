import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class HighlightBadgesDetailModal extends NavigationMixin(LightningElement) {
    @api badge;
    @api recordId;
    @api modalHeader;

    get navigationEnabled() {
        return (this.badge.recordId != this.recordId);
    }

    get fieldSet() {
        let fields = [];
        console.log(':::: fieldSet --> ' + this.badge.fieldSet);

        if (this.badge) {
            fields = this.badge.fieldSet.split(',');
        }
        console.log(':::: fields --> ' + fields);
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