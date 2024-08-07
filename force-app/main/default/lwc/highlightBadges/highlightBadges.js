import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { subscribe, onError } from 'lightning/empApi';
import getBadges from '@salesforce/apex/HighlightBadgesController.getBadges';
import userCanViewHighlightBadges from '@salesforce/customPermission/Can_View_Highlight_Badges';
import DEFINITION_OBJECT from '@salesforce/schema/Highlight_Badge_Definition__c';

export default class HighlightBadges extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api alertModalHeader = 'Highlight Badges Alerts';
    @api previewDefinitionId = '';
    
    wiredBadges = [];
    badges;
    @track selectedBadge;
    alertModalMessages = [];
    alertModalContent;
    alertModalBadges = [];

    error;
    errorMessage;
    isLoading = false;
    showModal = false;
    showModalAlert = false;

    showConfetti = false;
    confettiNumber = 'normal';
    confettiSize = 'medium';
    confettiType = 'default';

    refreshEventObjectName = 'Highlight_Badge_Refresh__e';
    definitionObject = DEFINITION_OBJECT;
    namespace = 'bdgs';
    subscription = {};
    recordIdsToRefresh = [];

    get channelName() {
        return this.definitionObject.objectApiName.substring(0,4) === this.namespace 
            ? '/event/' + this.namespace + '__' + this.refreshEventObjectName 
            : '/event/' + this.refreshEventObjectName;
    }

    get userHasBadgeAccess() {
        return userCanViewHighlightBadges;
    }

    connectedCallback() {
        this.registerErrorListener();
        this.handleSubscribe();
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            // Error contains the server-side error
            console.log('Received error from server: ', JSON.stringify(error));
        });
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = response => {
            const recordIdToRefresh = response.data.payload.Record_ID__c;
            if (this.hasRecordIdForRefresh(recordIdToRefresh)) {
                this.refresh();
            }
        };
        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            this.subscription = response;
        });
    }

    hasRecordIdForRefresh(recordIdToRefresh) {
        return this.recordIdsToRefresh.includes(recordIdToRefresh) || this.recordId == recordIdToRefresh;
    }

    get userHasBadgeAccess() {
        return userCanViewHighlightBadges;
    }

    get displayBadges() {
        return (this.userHasBadgeAccess && this.badges != null && this.badges.length > 0);
    }

    @wire(getBadges, {recordId: '$recordId', sObjectType: '$objectApiName', previewDefinitionId: '$previewDefinitionId'})
    wireResult(result) {
        this.isLoading = true;
        this.wiredBadges = result;
        if (result.data) {
            this.badges = JSON.parse(JSON.stringify(result.data));
            this.addRecordIdsForRefreshEvents(this.badges);
            this.handleAlerts(this.badges);
            // If a badge was previously selected, 
            // reset it using definitionId and recordId
            if (this.selectedBadge) this.refreshSelectedBadge();
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            this.badges = undefined;
            this.error = result.error;
            if (Array.isArray(this.error.body)) {
                this.errorMessage = this.error.body.map(e => e.message).join(', ');
            } else if (typeof this.error.body.message === 'string') {
                this.errorMessage = this.error.body.message;
            }
            this.isLoading = false;
        }
    }

    addRecordIdsForRefreshEvents(badges) {
        badges.forEach(badge => {
            this.recordIdsToRefresh.push(badge.sourceRecordId);
        });
    }

    handleAlerts(objs) {
        this.alertModalBadges = [];
        for (let i = 0; i < objs.length; i++) {
            const badge = objs[i];
            if (badge.hasAlert) {
                // Modal alerts
                if (badge.alertType == 'Modal') {
                    this.alertModalBadges.push(badge);
                } 
                // Toast alerts
                else if (badge.alertType == 'Toast') {
                    if (badge.sourceRecordId != this.recordId) {
                        // Add record link to alert message
                        this[NavigationMixin.GenerateUrl]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: badge.sourceRecordId,
                                actionName: 'view',
                            },
                        }).then((url) => {
                            const badgeAlertMessage = badge.alertMessage + ' | 🔍 {0}';
                            const messageData = [ 
                                {url, label: `View ${badge.sObjectTypeLabel}`} 
                            ];
                            this.showToast(badge.label, badgeAlertMessage, badge.toastVariant, badge.toastMode, badge.includeLabelInToast, messageData);
                        });
                    }
                    else {
                        this.showToast(badge.label, badge.alertMessage, badge.toastVariant, badge.toastMode, badge.includeLabelInToast);
                    }
                }
            }
            // Confetti
            if (badge.hasConfetti) {
                this.makeConfetti(badge.confettiNumber, badge.confettiSize);
            }
        }

        // Show modal if there are modal alerts and the user is not in the detail modal
        if (!this.showModal && this.alertModalBadges && this.alertModalBadges.length > 0) {
            this.showModalAlert = true;
        }
    }

    @api refresh() {
        refreshApex(this.wiredBadges);
    }

    refreshSelectedBadge() {
        const updatedBadge = this.badges.find(badge => 
            badge.definitionId === this.selectedBadge.definitionId && 
            badge.sourceRecordId === this.selectedBadge.sourceRecordId);
        if (updatedBadge) {
            this.selectedBadge = updatedBadge;
        } else {
            this.selectedBadge = undefined;
            this.showModal = false;
        }
    }

    handleBadgeClick(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.selectedBadge = this.badges.find(badge => {
            return badge.id === selectedId
        });
        this.showModal = true;
    }

    handleModalClose() {
        this.showModal = false;
        this.showModalAlert = false;
    }

    /**
     * @description Show toast message
     * @param title - The title of the toast
     * @param message - The message of the toast
     * @param variant - The variant of the toast
     * @param mode - The mode of the toast
     * @param includeLabel - If true, the definition label is displayed as the toast title
     * @param messageData - Optional data for the message template
     */
    showToast(title = 'Alert', message = ' ', variant = 'info', mode = 'dismissible', includeLabel = false, messageData = null) {
        const eventConfig = {
            message,
            variant,
            mode
        };

        // Set title if label should be included
        if (includeLabel) {
            eventConfig.title = title;
        }
    
        // If messageData is provided, add property to eventConfig
        if (messageData) {
            eventConfig.messageData = messageData;
        }
    
        const toast = new ShowToastEvent(eventConfig);
        this.dispatchEvent(toast);
    }

    /**
     * @description Rain confetti
     * @param size - The size of individual confetti items
     * @param type - Default/Emoji
     * @param number - The quantity of confetti items
     */
    makeConfetti(number = 'normal', size = 'medium', type = 'default') {
        this.confettiNumber = number;
        this.confettiSize = size;
        this.confettiType = type;
        this.showConfetti = true;
    }

}