import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getBadges from '@salesforce/apex/HighlightBadgesController.getBadges';
import canViewHighlightBadges from '@salesforce/customPermission/Can_View_Highlight_Badges';

export default class HighlightBadges extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api alertModalHeader = 'Highlight Badges Alerts';
    
    wiredBadges = [];
    badges;
    selectedBadge;
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

    get hasBadgeAccess() {
        return canViewHighlightBadges;
    }

    get displayBadges() {
        return (this.hasBadgeAccess && this.badges != null && this.badges.length > 0);
    }

    @wire(getBadges, {recordId: '$recordId', sObjectType: '$objectApiName'})
    wireResult(result) {
        this.isLoading = true;
        this.wiredBadges = result;
        if (result.data) {
            this.badges = JSON.parse( JSON.stringify(result.data) );
            this.handleAlerts(this.badges);
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
            console.error(this.error);
            this.isLoading = false;
        }
    }

    handleAlerts(objs) {
        for (let i = 0; i < objs.length; i++) {
            const badge = objs[i];
            if (badge.hasAlert) {
                // Modal alerts
                if (badge.alertType == 'Modal') {
                    this.alertModalBadges.push(badge);
                } 
                // Toast alerts
                else if (badge.alertType == 'Toast') {
                    if (badge.recordId != this.recordId) {
                        // Add record link to alert message
                        this[NavigationMixin.GenerateUrl]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: badge.recordId,
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

        // Show modal
        if (this.alertModalBadges && this.alertModalBadges.length > 0) {
            this.showModalAlert = true;
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