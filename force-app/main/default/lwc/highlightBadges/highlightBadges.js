import { LightningElement, api, wire } from 'lwc';
import getBadges from '@salesforce/apex/HighlightBadgesController.getBadges';
import canViewHighlightBadges from '@salesforce/customPermission/Can_View_Highlight_Badges';
import AlertsModal from 'c/highlightBadgesAlertsModal';

export default class HighlightBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api alertsModalHeader;
    
    wiredBadges = [];
    badges;
    selectedBadge;
    alertMessages = [];
    alertModalContent;

    error;
    errorMessage;
    isLoading = false;
    showModal = false;
    showAlert = false;

    get hasBadgeAccess() {
        return canViewHighlightBadges;
    }

    get displayBadges() {
        console.log(':::: has badge access --> ' + this.hasBadgeAccess);
        return (this.hasBadgeAccess && this.badges != null && this.badges.length > 0);
    }

    @wire(getBadges, {recordId: '$recordId', sObjectType: '$objectApiName'})
    wireResult(result) {
        this.isLoading = true;
        this.wiredBadges = result;
        if (result.data) {
            this.badges = result.data;

            for (let i = 0; i < this.badges.length; i++) {
                if (this.badges[i].hasAlert) {
                    if (this.alertMessages.includes(this.badges[i].alertMessage) === false) {
                        this.alertMessages.push(this.badge[i].alertMessage);
                    }
                }
            }
            if (this.alertMessages.length > 0) {
                this.alertModalContent = this.alertMessages.join("\n");
                this.showAlert();
            }

            this.error = undefined;
        } else if (result.error) {
            this.badges = undefined;
            this.error = result.error;
            if (Array.isArray(this.error.body)) {
                this.errorMessage = this.error.body.map(e => e.message).join(', ');
            } else if (typeof this.error.body.message === 'string') {
                this.errorMessage = this.error.body.message;
            }
            console.error(this.error);
        }
        this.isLoading = false;
    }

    async displayAlerts() {
        this.showAlert = true;

        const result = await AlertsModal.open({
            size: 'small', 
            description: 'Alerts', 
            alertsModalHeader: this.alertsModalHeader
        });

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
        this.showModal = false;
    }

}