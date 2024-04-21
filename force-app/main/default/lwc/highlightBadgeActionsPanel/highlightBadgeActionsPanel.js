import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import canRunFlows from '@salesforce/userPermission/RunFlow';

export default class HighlightBadgeActionsPanel extends NavigationMixin(LightningElement) {
    @api badge;
    @api actions;
    @api maxButtons = 3;

    buttonActions = [];
    overflowActions = [];
    selectedActionId;
    selectedAction;

    get hasRunFlowsAccess() {
        return canRunFlows;
    }

    connectedCallback() {
        this.loadActions();
    }

    loadActions() {
        let displayedTotal = 0;
        for (let i = 0; i < this.actions.length; i++) {
            const curAction = this.actions[i];
            // Do not include screen flow actions if the user can not run flows
            if (!this.verifyActionAccess(curAction)) continue;
            // Divide actions into buttons and overflow menu items
            if (displayedTotal < this.maxButtons) {
                this.buttonActions.push(this.actions[i]);
            } else {
                this.overflowActions.push(this.actions[i]);
            }
            displayedTotal++;
        }
    }

    verifyActionAccess(action) {
        if (
            action.recordTypeName === 'Flow' && 
            action.flowType === 'Screen Flow' && 
            !this.hasRunFlowsAccess
        ) {
            return false;
        }
        return true;
    }

    get hasOverflowActions() {
        return (this.overflowActions && this.overflowActions.length > 0);
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
        this.selectedAction = this.actions.find(action => {
            return action.id == actionId;
        });

        switch (this.selectedAction.recordTypeName) {
            case 'Navigation':
                if (this.selectedAction.navigationType === 'Source Record') {
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
        // Navigate to external page
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.selectedAction.url
            },
            target: '_blank'
        });
    }

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.badge.recordId,
                objectApiName: this.badge.sObjectType,
                actionName: 'view'
            }
        });
    }

    // Not yet offered as a navigation type
    /*
    navigateToKnowledgeArticle() {
        this[NavigationMixin.Navigate]({
            type: 'standard__knowledgeArticlePage',
            attributes: {
                articleType: 'Briefings',
                urlName: 'February-2017'
            }
        });
    }
    */

    handleFlow() {
        if (!this.selectedAction.flowType) {
            console.error('Flow type is missing.');
            return;
        }
        
        switch (this.selectedAction.flowType) {
            case 'Screen Flow':
                this.dispatchEvent(new CustomEvent('flowaction', {
                    detail: { 
                        flowApiName: this.selectedAction.flowApiName, 
                        includeRecordId: this.selectedAction.includeRecordId,
                        includeDisplayRecordId: this.selectedAction.includeDisplayRecordId
                    },
                    bubbles: true,
                    composed: true
                }));
                break;

            case 'Autolaunched Flow':
                console.log('Selected autolaunched flow');
                // do flow stuff

            default:
                console.alert(`Unhandled flow type: ${this.selectedAction.flowType}`);
        }
    }

}