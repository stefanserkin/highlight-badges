import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CreatorModal from 'c/highlightBadgeDefinitionCreatorModal';
import OBJECT_NAME from '@salesforce/schema/Highlight_Badge_Definition__c';

export default class NewHighlightBadgeDefinitionContainer extends NavigationMixin(LightningElement) {

    definitionObject = OBJECT_NAME;

    connectedCallback() {
        this.openModal();
    }

    async openModal() {
        const result = await CreatorModal.open({
            size: 'small',
            description: 'Create a new highlight badge definition'
        });
        console.log(result);
        if (this.isRecordId(result)) {
            this.handleNavigateToRecordPage(result);
        } else {
            this.handleNavigateToObjectHome();
        }
    }

    isRecordId(s) {
        return (s && (s.length == 15 || s.length == 18));
    }

    handleNavigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: this.definitionObject,
                actionName: 'view',
            },
        });
    }

    handleNavigateToObjectHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.definitionObject.objectApiName,
                actionName: 'home',
            },
        });
    }
}