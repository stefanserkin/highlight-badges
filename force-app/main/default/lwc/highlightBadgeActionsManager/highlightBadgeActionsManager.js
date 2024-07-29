import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from "@salesforce/apex";
import getActions from '@salesforce/apex/HighlightBadgeActionsMgrController.getActions';
import ActionsModal from 'c/highlightBadgeActionsManagerModal';

const ACTIONS = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

const COLS = [
    { fieldName: 'Label__c', label: 'Label', type: 'text' },
    { fieldName: 'recordTypeName', label: 'Type', type: 'text' },
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
        this.openModal('new');
    }

    handleRowAction(event) {
        const mode = event.detail.action;
        this.selectedAction = event.detail.row;
        switch (mode.name) {
            case 'edit':
                this.editAction(this.selectedAction.Id);
                break;
            case 'delete':
                this.deleteAction(this.selectedAction.Id);
                break;
        }
    }

    async openModal(mode) {
        const result = await ActionsModal.open({
            size: 'small',
            description: 'Manage highlight badge actions',
            definitionId: this.recordId,
            mode: mode,
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

    editAction(recordIdToEdit) {
        this.openModal('edit');
    }

    async deleteAction(recordIdToDelete) {
        try {
            await deleteRecord(recordIdToDelete);
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