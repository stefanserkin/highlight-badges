import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getBadges from '@salesforce/apex/HighlightBadgesController.getBadges';
import canViewHighlightBadges from '@salesforce/customPermission/Can_View_Highlight_Badges';

export default class HighlightBadges extends NavigationMixin(LightningElement) {
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
                if (badge.alertType == 'Modal') {
                    if (this.alertModalMessages.includes(badge.alertMessage) === false) {
                        // Add record link to alert message
                        if (badge.recordId != this.recordId) {
                            badge.alertMessage += ' - <a href="/' + badge.recordId + '">View Record</a>';
                        }
                        this.alertModalMessages.push(badge.alertMessage);
                    }
                } else if (badge.alertType == 'Toast') {
                    if (badge.recordId != this.recordId) {
                        // Add record link to alert message
                        this[NavigationMixin.GenerateUrl]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: badge.recordId,
                                actionName: 'view',
                            },
                        }).then((url) => {
                            const event = new ShowToastEvent({
                                variant: badge.toastVariant, 
                                mode: badge.toastMode, 
                                title: badge.label,
                                message: badge.alertMessage + ' - {0}',
                                messageData: [
                                    {
                                        url,
                                        label: 'View Record',
                                    },
                                ],
                            });
                            this.dispatchEvent(event);
                        });
                    } else {
                        this.showToast(badge.label, badge.alertMessage, badge.toastVariant, badge.toastMode);
                    }
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

    showToast(title = 'Alert', message = ' ', variant = 'info', mode = 'dismissible') {
        const toast = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        });
        this.dispatchEvent(toast);
    }

}