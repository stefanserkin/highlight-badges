import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import ID_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Id';
import LABEL_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Label__c';
import ICON_NAME_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Icon_Name__c';
import LABEL_COLOR_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Label_Color__c';
import BG_COLOR_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Background_Color__c';
import SOURCE_FIELDS_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Source_Detail_Fields__c';

const FIELDS = [
    ID_FIELD, 
    LABEL_FIELD, 
    ICON_NAME_FIELD, 
    LABEL_COLOR_FIELD, 
    BG_COLOR_FIELD, 
    SOURCE_FIELDS_FIELD
];

export default class HighlightBadgeDesigner extends LightningElement {
    @api recordId;
    error;
    originalDefinition;
    definition;

    label;
    iconName;
    labelColor;
    bgColor;
    sourceDetailFields;

    cardTitle = 'Badge Design Settings';
    isUpdateMode = false;

    get isEditDisabled() {
        return !this.isUpdateMode;
    }

    /**************************
     * Get highlight badge definition
     **************************/
    
    @wire(getRecord, {recordId: '$recordId', fields: FIELDS})
    wiredRecord({ error, data }) {
        if (error) {
            this.error = error;
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading highlight badge definition',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            this.originalDefinition = data;
            this.definition = data;
            this.setDefaultProperties(this.definition);
        }
    }

    setDefaultProperties(definition) {
        this.label = getFieldValue(definition, LABEL_FIELD);
        this.iconName = getFieldValue(definition, ICON_NAME_FIELD);
        this.labelColor = getFieldValue(definition, LABEL_COLOR_FIELD);
        this.bgColor = getFieldValue(definition, BG_COLOR_FIELD);
        this.sourceDetailFields = getFieldValue(definition, SOURCE_FIELDS_FIELD);
    }

    /**************************
     * Events
     **************************/

    handleSelectedIcon(event) {
        this.iconName = event.detail;
    }

    handleSelectedLabelColor(event) {
        this.labelColor = event.detail.value;
    }

    handleSelectedBgColor(event) {
        this.bgColor = event.detail.value;
    }

    handleLabelChange(event) {
        this.label = event.detail.value;
    }

    handleSourceDetailFieldsChange(event) {
        this.sourceDetailFields = event.detail.value;
    }

    /**************************
     * Actions
     **************************/

    handleSave() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[LABEL_FIELD.fieldApiName] = this.label;
        fields[ICON_NAME_FIELD.fieldApiName] = this.iconName;
        fields[BG_COLOR_FIELD.fieldApiName] = this.bgColor;
        fields[LABEL_COLOR_FIELD.fieldApiName] = this.labelColor;
        fields[SOURCE_FIELDS_FIELD.fieldApiName] = this.sourceDetailFields;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Badge definition updated",
                        variant: "success",
                    }),
                );
                this.isUpdateMode = false;
            })
            .catch((error) => {
                // The form is not valid
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Hmm... something went wrong",
                        message: "Check your input and try again.",
                        variant: "error",
                    })
                );
            });
    }

    handleEdit() {
        this.isUpdateMode = true;
    }

    handleCancel() {
        if (this.originalDefinition) {
            this.setDefaultProperties(this.originalDefinition);
        }
        this.isUpdateMode = false;
    }

}