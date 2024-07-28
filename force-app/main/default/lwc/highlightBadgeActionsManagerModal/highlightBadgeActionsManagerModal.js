import { api } from 'lwc';
import LightningModal from 'lightning/modal';

import ACTION_OBJECT from '@salesforce/schema/Highlight_Badge_Action__c';
import NAME_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Name';
import SORT_ORDER_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Sort_Order__c';
import LABEL_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Label__c';
import RECORDTYPEID_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.RecordTypeId';
import INCLUDE_SOURCE_ID_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Include_Source_Record_ID__c';
import INCLUDE_DISPLAY_ID_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Include_Display_Record_ID__c';
import FLOW_TYPE_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Flow_Type__c';
import NAVIGATION_TYPE_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Navigation_Type__c';
import FLOW_NAME_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Flow_API_Name__c';
import VARIANT_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Variant__c';
import ICON_NAME_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Icon_Name__c';
import ICON_POSITION_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Icon_Position__c';

const FIELDS = [
    NAME_FIELD,
    SORT_ORDER_FIELD,
    LABEL_FIELD,
    RECORDTYPEID_FIELD,
    INCLUDE_SOURCE_ID_FIELD,
    INCLUDE_DISPLAY_ID_FIELD,
    FLOW_TYPE_FIELD,
    NAVIGATION_TYPE_FIELD,
    FLOW_NAME_FIELD,
    VARIANT_FIELD,
    ICON_NAME_FIELD,
    ICON_POSITION_FIELD
];

export default class HighlightBadgeActionsManagerModal extends LightningModal {
    @api definitionId;
    @api mode;
    @api action;

    objectApiName = ACTION_OBJECT;
    fields = FIELDS;

    totalPages = 2;
    currentPage = 1;

    get modalHeader() {
        return this.mode === 'new' ? 'New Highlight Badge Action' : 'Edit Highlight Badge Action';
    }

    get isEditMode() {
        return this.mode === 'edit';
    }

    get isNewMode() {
        return this.mode === 'new';
    }

    handleNext() {
        this.currentPage++;
    }

    handlePrevious() {
        this.currentPage--;
    }

    previousIsDisabled() {
        this.currentPage === 1;
    }

    nextButtonLabel() {
        return this.currentPage < this.totalPages ? 'Next' : 'Save';
    }

    handleCancel() {
        this.close('cancel');
    }

    handleSuccess() {
        this.close('success');
    }
}