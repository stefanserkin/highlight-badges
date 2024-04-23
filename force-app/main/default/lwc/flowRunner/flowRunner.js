import { LightningElement, api } from 'lwc';

export default class FlowRunner extends LightningElement {
    @api flowName;
    @api recordId;
    @api displayRecordId;
    @api includeRecordId = false;
    @api includeDisplayRecordId = false;
    
    get inputVariables() {
        // Return null if no input is required
        if (!this.includeRecordId && !this.includeDisplayRecordId) {
            return;
        }

        // Add requested ids to input
        let results = [];
        if (this.includeRecordId) {
            results.push({
                name: 'recordId',
                type: 'String',
                value: this.recordId
            });
        }
        if (this.includeDisplayRecordId) {
            results.push({
                name: 'displayRecordId',
                type: 'String',
                value: this.displayRecordId
            });
        }
        return results;
    }

    handleStatusChange(event) {
        const { status, flowTitle, guid } = event.detail;
        console.log('::::: flow status --> ',status);
        console.log('::::: flow title --> ',flowTitle);
        console.log('::::: flow guid --> ',guid);

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
            this.dispatchEvent(new CustomEvent('finished'));
        }
    }
}