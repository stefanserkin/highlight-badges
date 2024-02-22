import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBadges from '@salesforce/apex/HighlightBadgesController.getBadges';
import AlertsModal from 'c/highlightBadgesAlertsModal';
import canViewHighlightBadges from '@salesforce/customPermission/Can_View_Highlight_Badges';

export default class HighlightBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api alertModalHeader;
    
    wiredBadges = [];
    badges;
    selectedBadge;
    alertModalMessages = [];
    alertToastMessages = [];
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
            console.log(':::: loaded badges');
            console.table(this.badges);
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
/*
    async displayAlerts() {
        this.showModalAlert = true;

        const result = await AlertsModal.open({
            size: 'small', 
            description: 'Alerts', 
            alertsModalHeader: this.alertsModalHeader
        });
    }
*/
    handleAlerts() {
        for (let i = 0; i < this.badges.length; i++) {
            let badge = this.badges[i];
            if (badge.hasAlert) {
                if (badge.alertType == 'Modal') {
                    console.log(':::: evaluating badge for modal --> ' + badge.id);
                    if (this.alertModalMessages.includes(badge.alertMessage) === false) {
                        console.log(':::: adding message --> ' + badge.alertMessage);
                        this.alertModalMessages.push(badge.alertMessage);
                    }
                } else if (badge.alertType == 'Toast') {
                    console.log(':::: evaluating badge for toast --> ' + badge.id);
                    if (this.alertToastMessages.includes(badge.alertMessage) === false) {
                        console.log(':::: adding message --> ' + badge.alertMessage);
                        this.alertToastMessages.push(badge.alertMessage);
                    }
                }
            }
        }
        if (this.alertModalMessages.length > 0) {
            console.log(':::: setting modal content');
            this.alertModalContent = this.alertModalMessages.join("\n");
            console.log(':::: setting modal content --> ' + this.alertModalContent);
            this.showModalAlert = true;
        }
        if (this.alertToastMessages.length > 0) {
            this.alertToastMessages.forEach(toast => {
                console.log('toast --> ' + toast);
                this.showToast(
                    this.alertModalHeader,
                    toast, 
                    'warning',
                    'sticky'
                );
            });
        }
    }

    handleBadgeClick(event) {
        const selectedId = event.currentTarget.dataset.id;
        console.log(':::: selectedId --> ' + selectedId);
        this.selectedBadge = this.badges.find(badge => {
            return badge.id === selectedId
        });
        console.log(':::: selectedBadge --> ' + this.selectedBadge);
        console.log(':::: fieldSet --> ' + this.selectedBadge.fieldSet);
        console.log(':::: recordId --> ' + this.selectedBadge.recordId);
        console.log(':::: obj type --> ' + this.selectedBadge.sObjectType);
        this.showModal = true;
    }

    handleModalClose() {
        console.log('handling modal close');
        this.showModal = false;
        this.showModalAlert = false;
    }

    showToast(title, message, variant, mode) {
        const toast = new ShowToastEvent({
            title,
            message,
            variant,
            mode,
        });
        this.dispatchEvent(toast);
    }

}