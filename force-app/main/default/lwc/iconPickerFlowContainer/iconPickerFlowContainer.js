import { LightningElement, api } from 'lwc';

export default class IconPickerFlowContainer extends LightningElement {
    @api iconName;

    handleSelectedIcon(event) {
        this.iconName = event.detail;
    }
}