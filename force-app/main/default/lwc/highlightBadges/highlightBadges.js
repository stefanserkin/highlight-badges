import { LightningElement, api, wire } from 'lwc';
import getBadges from '@salesforce/apex/HighlightBadgesController.getBadges';
import canViewHighlightBadges from '@salesforce/customPermission/Can_View_Highlight_Badges';
import AlertsModal from 'c/highlightBadgesAlertsModal';

export default class HighlightBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api alertModalHeader;
    
    wiredBadges = [];
    badges;
    selectedBadge;
    alertMessages = [];
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
        console.log(':::: has badge access --> ' + this.hasBadgeAccess);
        console.log(':::: this.badges --> ');
        console.table(this.badges);

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

            for (let i = 0; i < this.badges.length; i++) {
                if (this.badges[i].hasAlert) {
                    console.log(':::: evaluating badge --> ' + this.badges[i].id);
                    if (this.alertMessages.includes(this.badges[i].alertMessage) === false) {
                        console.log(':::: adding message --> ' + this.badges[i].alertMessage);
                        this.alertMessages.push(this.badges[i].alertMessage);
                    }
                }
            }
            if (this.alertMessages.length > 0) {
                console.log(':::: setting modal content');
                this.alertModalContent = this.alertMessages.join("\n");
                console.log(':::: setting modal content --> ' + this.alertModalContent);
                this.showModalAlert = true;
            }

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

    async displayAlerts() {
        this.showModalAlert = true;

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
        console.log('handling modal close');
        this.showModal = false;
        this.showModalAlert = false;
    }

}