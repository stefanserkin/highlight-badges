import { api } from 'lwc';
import LightningModal from 'lightning/modal';

import ACTION_OBJECT from '@salesforce/schema/Highlight_Badge_Action__c';

export default class HighlightBadgeActionsManagerModal extends LightningModal {
    @api definitionId;
    @api action;

    actionObject = ACTION_OBJECT;

    flowNameBase = 'Highlight_Badge_Action_Editor';
    namespace = 'bdgs';

    get flowName() {
        return this.actionObject.objectApiName.substring(0,4) === this.namespace 
            ? this.namespace + '__' + this.flowNameBase 
            : this.flowNameBase;
    }

    get flowInputVariables() {
        let results = [];
        results.push({
            name: 'definitionId',
            type: 'String',
            value: this.definitionId
        });
        if (this.action) {
            results.push({
                name: 'actionId',
                type: 'String',
                value: this.action.Id
            });
        }
        return results;
    }

    handleStatusChange(event) {
        const { status, flowTitle, guid } = event.detail;
        /*
        These are the valid status values for a flow interview.
        STARTED: The interview is started and ongoing.
        PAUSED: The interview is paused successfully.
        FINISHED: The interview for a flow with screens is finished.
        FINISHED_SCREEN: The interview for a flow without screens is finished.
        ERROR: Something went wrong and the interview failed.

        https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowinterview.htm
         */
        if (status === 'FINISHED') {
            console.log(':::: completed the flow');
            this.handleSuccess();
        }
    }

    handleCancel() {
        this.close('cancel');
    }

    handleSuccess() {
        this.close('success');
    }

}