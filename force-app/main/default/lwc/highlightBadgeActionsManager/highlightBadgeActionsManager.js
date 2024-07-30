import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from "@salesforce/apex";
import getActions from '@salesforce/apex/HighlightBadgeActionsMgrController.getActions';
import ActionsModal from 'c/highlightBadgeActionsManagerModal';
import LABEL_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Label__c';
import SORT_ORDER_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Sort_Order__c';
import ACTIVE_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.Active__c';

const ACTIONS = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

const COLS = [
    { fieldName: 'label', label: 'Label', type: 'text' },
    { fieldName: 'recordTypeName', label: 'Type', type: 'text' },
    { fieldName: 'active', label: 'Active', type: 'boolean' },
    { fieldName: 'sortOrder', label: 'Sort Order', type: 'number' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS, menuAlignment: 'auto' } }
];

export default class HighlightBadgeActionsManager extends NavigationMixin(LightningElement) {
    @api recordId;
    error;
    isLoading = false;

    cols = COLS;

    wiredActions = [];
    actions;
    selectedAction;

    @wire(getActions, { recordId: '$recordId' })
    wiredActionsResult(result) {
        this.isLoading = true;
        this.wiredActions = result;

        if (result.data) {
            let rows = JSON.parse( JSON.stringify(result.data) );
            rows.forEach(row => {
                row.label = row[LABEL_FIELD.fieldApiName];
                row.active = row[ACTIVE_FIELD.fieldApiName];
                row.sortOrder = row[SORT_ORDER_FIELD.fieldApiName];
                row.recordTypeName = row.RecordType.Name;
            });
            this.actions = rows;
            this.error = undefined;
        } else if (result.error) {
            this.actions = undefined;
            this.error = result.error;
        }
        this.isLoading = false;
    }

    get numberOfActions() {
        return this.actions && this.actions.length ? this.actions.length : 0;
    }

    handleCreateNewAction() {
        this.selectedAction = undefined;
        this.openModal();
    }

    handleRowAction(event) {
        const mode = event.detail.action;
        this.selectedAction = event.detail.row;
        switch (mode.name) {
            case 'edit':
                this.editAction();
                break;
            case 'delete':
                this.deleteAction();
                break;
        }
    }

    editAction() {
        this.openModal();
    }

    async openModal() {
        const result = await ActionsModal.open({
            size: 'small',
            description: 'Manage highlight badge actions',
            definitionId: this.recordId,
            action: this.selectedAction
        });
        if (result === 'success') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    variant: 'success'
                })
            );
            await refreshApex(this.wiredActions);
        }
    }

    async deleteAction() {
        try {
            await deleteRecord(this.selectedAction.Id);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Action deleted',
                    variant: 'success'
                })
            );
            await refreshApex(this.wiredActions);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting record',
                    message: reduceErrors(error).join(', '),
                    variant: 'error'
                })
            );
        }
    }
    
}