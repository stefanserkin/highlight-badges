import { LightningElement, api, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getDisplayObjects from '@salesforce/apex/HighlightBadgeSetupController.getDisplayObjects';
import getChildObjects from '@salesforce/apex/HighlightBadgeSetupController.getChildObjects';
import getCommonAncestorObjects from '@salesforce/apex/HighlightBadgeSetupController.getCommonAncestorObjects';
import findInverseRelationshipField from '@salesforce/apex/HighlightBadgeSetupController.findInverseRelationshipField';
import findRelationshipFields from '@salesforce/apex/HighlightBadgeSetupController.getPossibleAncestorPaths';

import BADGE_DEFINITION_OBJECT from '@salesforce/schema/Highlight_Badge_Definition__c';
import ID_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Id';
import DISPLAY_OBJ_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Display_Object__c';
import SOURCE_OBJ_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Source_Object__c';
import ANCESTOR_OBJ_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Common_Ancestor_Object__c';
import SOURCE_PATH_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Source_to_Ancestor_Path__c';
import DISPLAY_PATH_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Display_to_Ancestor_Path__c';
import SORT_ORDER_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Sort_Order__c';

export default class HighlightBadgeObjectWizard extends LightningElement {
    @api recordId;

    isLoading = false;
    error;

    wiredDisplayObjects = [];
    displayObjects;
    childObjects;
    commonAncestorObjects;

    selectedDisplayObject;
    sortOrder = 1.00;
    selectedSourceObject;
    selectedDisplayChildRelationship;
    selectedCommonAncestorObject;
    selectedSourceObjectRelationship;
    selectedAncestorType;
    hasLoadedChildObjects = false;
    hasLoadedCommonAncestors = false;
    hasLoadedRelationshipPaths = false;

    ancestorRelationshipPaths;
    displayRelationshipPaths;
    sourceRelationshipPaths;
    selectedDisplayRelationshipPath;
    selectedSourceRelationshipPath;
    
    badgeDefinitionId;

    @wire(getDisplayObjects)
    wiredDisplayObjResult(result) {
        this.isLoading = true;
        this.wiredDisplayObjects = result;
        if (result.data) {
            let rows = JSON.parse( JSON.stringify(result.data) );
            this.displayObjects = this.sortObjectsByLabel(rows);
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            this.displayObjects = undefined;
            this.error = result.error;
            console.error(this.error);
            this.isLoading = false;
        }
    }

    get saveDisabled() {
        return (
            this.selectedDisplayObject == null || 
            this.selectedSourceObject == null || 
            this.selectedCommonAncestorObject == null || 
            this.selectedDisplayRelationshipPath == null || 
            this.selectedSourceRelationshipPath == null
        );
    }

    get displayObjectOptions() {
        return this.getObjectsAsPicklistValues(this.displayObjects);
    }

    get childObjectOptions() {
        return this.getObjectsAsPicklistValues(this.childObjects);
    }

    get commonAncestorOptions() {
        return this.getObjectsAsPicklistValues(this.commonAncestorObjects);
    }

    get displayPathOptions() {
        let options = [];
        this.displayRelationshipPaths.forEach(path => {
            options.push({label: path, value: path});
        });
        return options;
    }

    get sourcePathOptions() {
        let options = [];
        this.sourceRelationshipPaths.forEach(path => {
            options.push({label: path, value: path});
        });
        return options;
    }

    get sourceObjectRelationshipOptions() {
        return [
            {label: `The display ${this.selectedDisplayObject}`, value: 'same'},
            {label: 'A related object', value: 'related'},
        ];
    }

    get ancestorTypeOptions() {
        return [
            {label: `The display ${this.selectedDisplayObject}`, value: 'display'},
            {label: 'A common ancestor', value: 'ancestor'},
        ];
    }

    get sourceIsRelatedObject() {
        return this.selectedSourceObjectRelationship == 'related' && this.selectedDisplayObject != null && this.selectedDisplayObject.length > 0;
    }

    get showCommonAncestorPicklist() {
        return this.selectedAncestorType == 'ancestor' && this.hasLoadedCommonAncestors;
    }

    handleDisplayObjectChange(event) {
        const selectedObj = event.detail.value;
        this.selectedDisplayObject = selectedObj;
        this.loadChildObjects();
    }

    handleSortOrderChange(event) {
        this.sortOrder = event.detail.value;
    }

    handleSourceObjectRelationshipChange(event) {
        const selectedVal = event.detail.value;
        this.selectedSourceObjectRelationship = selectedVal;
        if (this.selectedSourceObjectRelationship == 'same') {
            this.selectedSourceObject = this.selectedDisplayObject;
            this.selectedCommonAncestorObject = this.selectedDisplayObject;
            this.selectedDisplayRelationshipPath = 'Id';
            this.selectedSourceRelationshipPath = 'Id';
        }
    }

    handleSourceObjectChange(event) {
        const selectedObj = event.detail.value;
        this.selectedDisplayChildRelationship = selectedObj;

        // Get child object name based on child relationship
        const childObj = this.childObjects.find(obj => obj.childRelationshipName === selectedObj);
        this.selectedSourceObject = childObj.name;

        if (this.selectedAncestorType == 'ancestor') {
            this.loadAncestorObjects();
        }
    }

    handleAncestorTypeChange(event) {
        this.selectedAncestorType = event.detail.value;
        if (this.selectedAncestorType == 'display') {
            this.selectedDisplayRelationshipPath = 'Id';
            this.selectedCommonAncestorObject = this.selectedDisplayObject;

            findInverseRelationshipField({
                ancestorObjectName: this.selectedDisplayObject, 
                childObjectName: this.selectedSourceObject, 
                relationshipName: this.selectedDisplayChildRelationship
            })
            .then(result => {
                this.selectedSourceRelationshipPath = result;
            })
            .catch(error => {
                console.error(error);
            });
            
        } else if (this.selectedAncestorType == 'ancestor') {
            this.loadAncestorObjects();
        }
    }

    handleCommonAncestorObjectChange(event) {
        const selectedObj = event.detail.value;
        this.selectedCommonAncestorObject = selectedObj;
        this.fetchRelationshipPaths();
    }

    handleSelectedDisplayPath(event) {
        this.selectedDisplayRelationshipPath = event.detail.value;
    }

    handleSelectedSourcePath(event) {
        this.selectedSourceRelationshipPath = event.detail.value;
    }

    loadChildObjects() {
        if (this.selectedDisplayObject) {
            getChildObjects({objName: this.selectedDisplayObject})
            .then(result => {
                let rows = JSON.parse(JSON.stringify(result));
                this.childObjects = this.sortObjectsByLabel(rows);
                this.hasLoadedChildObjects = true;
            })
            .catch(error => {
                this.error = error;
                console.error(this.error);
            });
        }
    }

    loadAncestorObjects() {
        if (this.selectedDisplayObject && this.selectedSourceObject) {
            getCommonAncestorObjects({
                displayObject: this.selectedDisplayObject, 
                sourceObject: this.selectedSourceObject
            })
            .then(result => {
                let rows = JSON.parse(JSON.stringify(result));
                this.commonAncestorObjects = this.sortObjectsByLabel(rows);
                this.hasLoadedCommonAncestors = true;
                this.error = undefined;
            })
            .catch(error => {
                this.commonAncestorObjects = undefined;
                this.error = error;
                console.error(this.error);
            });
        } else {
            return null;
        }
    }

    fetchRelationshipPaths() {
        findRelationshipFields({ 
            displayObjectApiName: this.selectedDisplayObject,
            sourceObjectApiName: this.selectedSourceObject,
            commonAncestorApiName: this.selectedCommonAncestorObject
        })
        .then(result => {
            this.ancestorRelationshipPaths = result;
            this.ancestorRelationshipPaths.forEach(arp => {
                if (arp.type == 'display') {
                    this.displayRelationshipPaths = arp.relationships;
                } else if (arp.type == 'source') {
                    this.sourceRelationshipPaths = arp.relationships;
                }
            });
            this.hasLoadedRelationshipPaths = true;
        })
        .catch(error => {
            console.error('Error fetching relationship paths --> ', error);
        });
    }

    handleSave() {
        this.isLoading = true;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[DISPLAY_OBJ_FIELD.fieldApiName] = this.selectedDisplayObject;
        fields[SOURCE_OBJ_FIELD.fieldApiName] = this.selectedSourceObjectRelationship == 'same' ? this.selectedDisplayObject : this.selectedSourceObject;
        fields[ANCESTOR_OBJ_FIELD.fieldApiName] = this.selectedCommonAncestorObject;
        fields[DISPLAY_PATH_FIELD.fieldApiName] = this.selectedDisplayRelationshipPath;
        fields[SOURCE_PATH_FIELD.fieldApiName] = this.selectedSourceObjectRelationship == 'same' ? 'Id' : this.selectedSourceRelationshipPath;
        fields[SORT_ORDER_FIELD.fieldApiName] = this.sortOrder;
        
        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "The object settings were updated",
                        variant: "success",
                    }),
                );
                this.isLoading = false;
                this.handleClose();
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: error.body.message,
                        variant: "error",
                    }),
                );
                this.isLoading = false;
            });
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    /**
     * Dynamic labels
     */

    get displayToAncestorPathLabel() {
        return `API Path from the display object (${this.selectedDisplayObject}) to the common ancestor (${this.selectedCommonAncestorObject})`;
    }

    get sourceToAncestorPathLabel() {
        return `API Path from the source object (${this.selectedSourceObject}) to the common ancestor (${this.selectedCommonAncestorObject})`;
    }

    /**
     * Utils
     */

    sortObjectsByLabel(lstObjects) {
        lstObjects.sort((a, b) => {
            const labelA = a.label.toUpperCase();
            const labelB = b.label.toUpperCase();
            return labelA.localeCompare(labelB);
        });
        return lstObjects;
    }

    getObjectsAsPicklistValues(lstObjects) {
        let options = [];
        if (lstObjects != null) {
            lstObjects.forEach(obj => {
                const nameValue = obj.childRelationshipName != null ? obj.childRelationshipName : obj.name;
                const pickLabel = obj.label + ' (' + nameValue + ')';
                const pickObj = {
                    label: pickLabel, 
                    value: nameValue
                };
                options.push(pickObj);
            });
        }
        return options;
    }

}