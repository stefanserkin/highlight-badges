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
import URL_FIELD from '@salesforce/schema/Highlight_Badge_Action__c.URL__c';

export default class HighlightBadgeActionsManagerModal extends LightningModal {
    @api definitionId;
    @api action;

    flowName = 'Highlight_Badge_Action_Editor';

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