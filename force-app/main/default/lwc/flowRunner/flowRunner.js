import { LightningElement, api } from 'lwc';

export default class FlowRunner extends LightningElement {
    @api flowName;
    @api recordId;
    @api displayRecordId;
    
    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId,
            },
            {
                name: 'displayRecordId',
                type: 'String',
                value: this.displayRecordId,
            },
        ];
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
         */
        if (status === 'FINISHED') {
            console.log(':::: completed the flow');
            this.dispatchEvent(new CustomEvent('finished'));
        }
    }
}