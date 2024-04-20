import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class HighlightBadgeActionsPanel extends NavigationMixin(LightningElement) {
    @api badge;
    @api actions;
    @api maxButtons = 3;

    buttonActions = [];
    overflowActions = [];
    selectedActionId;
    selectedAction;

    connectedCallback() {
        this.loadActions();
    }

    loadActions() {
        for (let i = 0; i < this.actions.length; i++) {
            if (i < this.maxButtons) {
                this.buttonActions.push(this.actions[i]);
            } else {
                this.overflowActions.push(this.actions[i]);
            }
        }
    }

    handleSelectedButtonAction(event) {
        this.selectedActionId = event.target.dataset.id;
        this.handleAction(this.selectedActionId);
    }

    handleSelectedOverflowAction(event) {
        this.selectedActionId = event.detail.value;
        this.handleAction(this.selectedActionId);
    }

    handleAction(actionId) {
        console.log('action id --> ',actionId);
        this.selectedAction = this.actions.find(action => {
            return action.id == actionId;
        });
        console.log(JSON.stringify(this.selectedAction));

        switch (this.selectedAction.recordTypeName) {
            case 'Navigation':
                if (this.selectedAction.navigationType === 'View Source Record') {
                    this.navigateToRecord();
                } else {
                    this.navigateToUrl();
                }
                break;
            case 'Flow':
                this.handleFlow();
                break;
            default:
                console.error('Unhandled action type:', this.selectedAction.type);
        }
    }

    navigateToUrl() {
        // Guard against empty action url
        if (!this.selectedAction.url) {
            console.error('URL is missing for navigation action.');
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.selectedAction.url
            },
            target: '_blank'
        });
    }

    navigateToRecord() {
        console.log('ready to navigate to record');
        console.log(JSON.stringify(this.badge));
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.badge.recordId,
                objectApiName: this.badge.sObjectType,
                actionName: 'view'
            }
        });
    }

    handleFlow() {
        if (!this.selectedAction.flowType) {
            console.error('Flow type is missing.');
            return;
        }
        
        switch (this.selectedAction.flowType) {
            case 'Screen Flow':
                this.dispatchEvent(new CustomEvent('handleflow', {
                    detail: { flowApiName: this.selectedAction.flowApiName },
                    bubbles: true,
                    composed: true
                }));
                break;

            case 'Autolaunched Flow':
                console.log('Selected autolaunched flow');
                // do something else

            default:
                console.alert(`Unhandled flow type: ${this.selectedAction.flowType}`);
        }
    }

}