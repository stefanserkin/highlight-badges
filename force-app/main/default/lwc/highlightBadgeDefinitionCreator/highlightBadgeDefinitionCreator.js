import { LightningElement, api } from 'lwc';
import DEFINITION_OBJECT from '@salesforce/schema/Highlight_Badge_Definition__c';
import NAME_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Name';
import SORT_ORDER_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Sort_Order__c';

export default class HighlightBadgeDefinitionCreator extends LightningElement {
    isLoading = false;
    recordId;

    definitionObject = DEFINITION_OBJECT;
    nameField = NAME_FIELD;
    sortOrderField = SORT_ORDER_FIELD;

    handleSuccess(event) {
        this.recordId = event.detail.id;
        this.dispatchEvent(
            new CustomEvent('success', {
                detail: {
                    recordId: this.recordId
                },
            })
        );
    }

    handleCancel() {
        this.dispatchEvent( new CustomEvent('cancel') );
    }

}