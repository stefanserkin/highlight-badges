import { LightningElement, api, wire, track } from 'lwc';
import search from '@salesforce/apex/LookupController.search';
import getDefault from '@salesforce/apex/LookupController.getDefault';

export default class Lookup extends LightningElement {
    @api objectApiName;
    @api iconName;
    @api filter = '';
    @api searchPlaceholder = 'Search';
    @api defaultRecordId;

    wiredDefaultRecord = [];
    @track selectedId;
    @track selectedName;
    @track isValueSelected;
    @track searchRecords;
    @track blurTimeout;

    searchInput;
    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    isLoading = false;
    error;

    @wire(getDefault, {defaultRecordId: '$defaultRecordId', sObjectType: '$objectApiName'})
    wiredDefaultResult(result) {
        this.isLoading = true;
        this.wiredDefaultRecord = result;
        if (result.data) {
            const row = result.data;
            this.selectedId = row.Id;
            this.selectedName = row.Name;
            this.isValueSelected = true;
        } else if (result.error) {
            console.error(result.error);
            this.error = result.error;
        }
    }

    @wire(search, {searchInput : '$searchInput', sObjectType : '$objectApiName', filter : '$filter'})
    wiredRecords({ error, data }) {
        if (data) {
            this.searchRecords = data;
            this.error = undefined;
        } else if (error) {
            this.searchRecords = undefined;
            this.error = error;
        }
    }

    get recordUrl() {
        return this.selectedId != null ? '/' + this.selectedId : '';
    }

    get objectIsMetadata() {
        const objSuffix = this.objectApiName.slice(-3);
        return objSuffix === 'mdt' ? true : false;
    }

    handleClick() {
        this.searchInput = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    handleBlur() {
        this.blurTimeout = setTimeout(() => {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    handleSelection(event) {
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;
        const valueSelectedEvent = new CustomEvent('selection', { detail:  selectedId });
        this.dispatchEvent(valueSelectedEvent);
        this.isValueSelected = true;
        this.selectedId = selectedId;
        this.selectedName = selectedName;
        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    handleRemovePill() {
        this.isValueSelected = false;
    }

    handleSearchInputChange(event) {
        this.searchInput = event.target.value;
    }
}