import { LightningElement, api, wire } from 'lwc';
import { deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from "@salesforce/apex";
import getActions from '@salesforce/apex/HighlightBadgeActionsMgrController.getActions';

const ACTIONS = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

const COLS = [
    { fieldName: 'Label__c', label: 'Label', type: 'text' },
    { fieldName: 'recordTypeName', label: 'Type', type: 'text' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS, menuAlignment: 'auto' } }
];

export default class HighlightBadgeActionsManager extends LightningElement {
    @api recordId;
    error;
    isLoading = false;

    cols = COLS;

    wiredActions = [];
    actions;

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
        alert(`Hooray! But that's not ready yet`);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        console.log('::::: selected action --> ',action);
        const row = event.detail.row;
        switch (action.name) {
            case 'edit':
                alert('Edit Action: ' + JSON.stringify(row));
                break;
            case 'delete':
                this.deleteAction(row.Id);
                break;
        }
    }

    async deleteAction(recordIdToDelete) {
        // const recordId = event.target.dataset.recordid;

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