import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACTIVE_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Active__c';
import LABEL_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Label__c';
import ICON_NAME_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Icon_Name__c';
import LABEL_COLOR_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Label_Color__c';
import BG_COLOR_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Background_Color__c';
import DISPLAY_OBJECT_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Display_Object__c';

const FIELDS = [ACTIVE_FIELD, LABEL_FIELD, ICON_NAME_FIELD, LABEL_COLOR_FIELD, BG_COLOR_FIELD, DISPLAY_OBJECT_FIELD];

export default class HighlightBadgePreview extends LightningElement {
    @api recordId;
    error;
    definition;
    isLoading = false;

    active = false;
    label;
    iconName;
    labelColor;
    bgColor;
    displayObject;

    defaultLabelColor = '#000000';
    defaultBgColor = '#D3D3D3';
    defaultIconName = 'utility:info';

    isRecordPreviewMode = false;
    previewRecordId;

    @wire(getRecord, {recordId: '$recordId', fields: FIELDS})
    wiredRecord({ error, data }) {
        if (data) {
            this.definition = data;
            this.active = getFieldValue(this.definition, ACTIVE_FIELD);
            this.label = getFieldValue(this.definition, LABEL_FIELD);
            this.iconName = getFieldValue(this.definition, ICON_NAME_FIELD);
            this.labelColor = getFieldValue(this.definition, LABEL_COLOR_FIELD);
            this.bgColor = getFieldValue(this.definition, BG_COLOR_FIELD);
            this.displayObject = getFieldValue(this.definition, DISPLAY_OBJECT_FIELD);
        } else if (error) {
            this.handleError(error, 'Error loading highlight badge definition');
        }
    }

    get isInactive() {
        return !this.active;
    }

    get colorStyle() {
        const hexColor = !this.bgColor ? this.defaultBgColor : this.bgColor;
        return '--sds-c-badge-color-background:' + hexColor + ';';
    }

    get labelStyle() {
        const hexColor = !this.labelColor ? this.defaultLabelColor : this.labelColor;
        return '--sds-c-badge-text-color:' + hexColor + ';--slds-c-badge-icon-color-foreground:' + hexColor;
    }

    get styles() {
        return this.colorStyle + this.labelStyle;
    }

    get icon() {
        return !this.iconName ? this.defaultIconName : this.iconName;
    }

    get togglePreviewModeIcon() {
        return this.isRecordPreviewMode ? 'utility:close' : 'utility:preview';
    }

    get togglePreviewModeLabel() {
        return this.isRecordPreviewMode ? 'Exit Record Preview' : 'Record Preview Mode';
    }

    get togglePreviewModeVariant() {
        return this.isRecordPreviewMode ? 'destructive-text' : 'neutral';
    }

    handlePreviewRecordIdChange(event) {
        this.previewRecordId = event.detail.value;
    }

    handleSelectedRecord(event) {
        this.previewRecordId = event.detail;
    }

    handleTogglePreviewMode() {
        this.isRecordPreviewMode = !this.isRecordPreviewMode;
    }

    handleRefresh() {
        this.template.querySelector('c-highlight-badges').refresh();
    }

    handleError(error, title='Error') {
        this.error = error;
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message,
                variant: 'error',
            }),
        );
    }

}