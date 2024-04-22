import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runFlow from '@salesforce/apex/HighlightBadgesController.runFlow';
import canRunFlows from '@salesforce/userPermission/RunFlow';

export default class HighlightBadgeActionsPanel extends NavigationMixin(LightningElement) {
    @api badge;
    @api actions;
    @api recordId;
    @api maxButtons = 3;
    error;

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

    /**
     * Route traffic
     */
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
                console.error('Unhandled action type:', this.selectedAction.recordTypeName);
        }
    }

    /**
     * Navigation
     */
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

    /**
     * Flows
     */
    handleFlow() {
        if (!this.selectedAction.flowType || !this.selectedAction.flowApiName) {
            console.error('Flow details are missing from the highlight badge action.');
            return;
        }
        
        switch (this.selectedAction.flowType) {
            case 'Screen Flow':
                // Screen flows are run from the parent component, so just communicate
                // the flow details back to the parent component
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
                this.runAutolaunchedFlow();
                break;

            default:
                console.error(`Unhandled flow type: ${this.selectedAction.flowType}`);
        }
    }

    runAutolaunchedFlow() {
        const flowName = this.selectedAction.flowApiName;
        const inputVariables = JSON.stringify(this.flowInputVariables);
        runFlow({ flowName: flowName, jsonInputVariables: inputVariables })
            .then(result => {
                if (result === 'success') {
                    const evt = new ShowToastEvent({
                        title: 'Success!',
                        message: 'The flow ran successfully.',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    this.dispatchEvent(new CustomEvent('refresh'));
                }
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: 'Hmm... something went wrong',
                    message: 'An error occurred while running the flow.',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });
    }

    get flowInputVariables() {
        const includeRecordId = this.selectedAction.includeRecordId;
        const includeDisplayRecordId = this.selectedAction.includeDisplayRecordId;
        // Return null if no input is required
        if (!includeRecordId && !includeDisplayRecordId) {
            return;
        }

        // Add requested ids to input
        let input = {};
        if (includeRecordId) {
            input['recordId'] = this.badge.recordId;
        }
        if (includeDisplayRecordId) {
            input['displayRecordId'] = this.recordId;
        }
        return input;
    }

}