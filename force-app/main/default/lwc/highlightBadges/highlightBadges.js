import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBadges from '@salesforce/apex/HighlightBadgesController.getBadges';
import canViewHighlightBadges from '@salesforce/customPermission/Can_View_Highlight_Badges';

export default class HighlightBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api alertModalHeader;
    
    wiredBadges = [];
    badges;
    selectedBadge;
    alertModalMessages = [];
    alertModalContent;

    error;
    errorMessage;
    isLoading = false;
    showModal = false;
    showModalAlert = false;

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
            this.badges = result.data;
            this.handleAlerts();
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

    handleAlerts() {
        for (let i = 0; i < this.badges.length; i++) {
            const badge = this.badges[i];
            if (badge.hasAlert) {
                if (badge.alertType == 'Modal') {
                    if (this.alertModalMessages.includes(badge.alertMessage) === false) {
                        this.alertModalMessages.push(badge.alertMessage);
                    }
                } else if (badge.alertType == 'Toast') {
                    this.showToast(badge.label, badge.alertMessage, badge.toastVariant, badge.toastMode);
                }
            }
        }
        // Modal alerts are displayed together in a single modal
        if (this.alertModalMessages.length > 0) {
            this.alertModalContent = this.alertModalMessages.join("\n");
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

    showToast(title, message, variant, mode) {
        const toast = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        });
        this.dispatchEvent(toast);
    }

}