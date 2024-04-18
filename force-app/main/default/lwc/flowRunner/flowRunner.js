import { LightningElement, api } from 'lwc';

export default class FlowRunner extends LightningElement {
    @api flowName;
    @api recordId;
    
    get inputVariables() {
        return [{
            name: 'recordId',
            type: 'String',
            value: this.recordId,
        }];
    }

    handleStatusChange(event) {
        const { status, flowTitle, guid } = event.detail;
        console.log('::::: flow status --> ',status);
        console.log('::::: flow title --> ',flowTitle);
        console.log('::::: flow guid --> ',guid);
        if (status === 'FINISHED') {
            console.log(':::: completed the flow');
            this.dispatchEvent(new CustomEvent('finished'));
        }
    }
}