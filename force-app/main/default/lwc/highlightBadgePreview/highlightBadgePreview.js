import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import LABEL_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Label__c';
import ICON_NAME_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Icon_Name__c';
import LABEL_COLOR_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Label_Color__c';
import BG_COLOR_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Background_Color__c';

const FIELDS = [LABEL_FIELD, ICON_NAME_FIELD, LABEL_COLOR_FIELD, BG_COLOR_FIELD];

export default class HighlightBadgePreview extends LightningElement {
    @api recordId;
    error;
    definition;

    label;
    iconName;
    labelColor;
    bgColor;

    defaultLabelColor = '#000000';
    defaultBgColor = '#D3D3D3';
    defaultIconName = 'utility:info';

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
            this.definition = data;
            this.label = getFieldValue(this.definition, LABEL_FIELD);
            this.iconName = getFieldValue(this.definition, ICON_NAME_FIELD);
            this.labelColor = getFieldValue(this.definition, LABEL_COLOR_FIELD);
            this.bgColor = getFieldValue(this.definition, BG_COLOR_FIELD);
        }
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

}