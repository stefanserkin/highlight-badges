import { LightningElement, api, wire } from 'lwc';
import getBadges from '@salesforce/apex/HighlightBadgesController.getBadges';
import canViewHighlightBadges from "@salesforce/userPermission/Can_View_Highlight_Badges";

export default class HighlightBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api modalHeader;
    
    wiredBadges = [];
    badges;
    selectedBadge;

    error;
    errorMessage;
    isLoading = false;
    showModal = false;

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