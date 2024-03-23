import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getDisplayObjects from '@salesforce/apex/HighlightBadgeSetupController.getDisplayObjects';
import getChildObjects from '@salesforce/apex/HighlightBadgeSetupController.getChildObjects';
import getCommonParentObjects from '@salesforce/apex/HighlightBadgeSetupController.getCommonParentObjects';
import findInverseRelationshipField from '@salesforce/apex/HighlightBadgeSetupController.findInverseRelationshipField';
import findRelationshipFields from '@salesforce/apex/HighlightBadgeSetupController.getPossibleAncestorPaths';

import BADGE_DEFINITION_OBJECT from '@salesforce/schema/Highlight_Badge_Definition__c';
import NAME_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Name';
import DISPLAY_OBJ_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Display_Object__c';
import SOURCE_OBJ_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Source_Object__c';
import ANCESTOR_OBJ_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Common_Ancestor_Object__c';
import SOURCE_PATH_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Source_to_Ancestor_Path__c';
import DISPLAY_PATH_FIELD from '@salesforce/schema/Highlight_Badge_Definition__c.Display_to_Ancestor_Path__c';

export default class HighlightBadgeSetup extends NavigationMixin(LightningElement) {
    isLoading = false;
    error;

    wiredDisplayObjects = [];
    displayObjects;
    childObjects;
    commonAncestorObjects;

    badgeDefinitionName = '';
    selectedDisplayObject;
    selectedSourceObject;
    selectedDisplayChildRelationship;
    selectedCommonParentObject;
    selectedSourceObjectRelationship;
    selectedAncestorType;
    hasLoadedChildObjects = false;
    hasLoadedCommonParents = false;
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
            this.badgeDefinitionName == null || 
            this.selectedDisplayObject == null || 
            this.selectedSourceObject == null || 
            this.selectedCommonParentObject == null || 
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
        console.log(options);
        return options;
    }

    get sourcePathOptions() {
        let options = [];
        this.sourceRelationshipPaths.forEach(path => {
            options.push({label: path, value: path});
        });
        console.log(options);
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
        return this.selectedAncestorType == 'ancestor' && this.hasLoadedCommonParents;
    }

    handleNameChange(event) {
        console.log(event.detail.value);
        this.badgeDefinitionName = event.detail.value;
    }

    handleDisplayObjectChange(event) {
        const selectedObj = event.detail.value;
        console.log(selectedObj);
        this.selectedDisplayObject = selectedObj;
        this.resetForm();
        this.loadChildObjects();
    }

    handleSourceObjectRelationshipChange(event) {
        const selectedVal = event.detail.value;
        console.log(selectedVal);
        this.selectedSourceObjectRelationship = selectedVal;
        if (this.selectedSourceObjectRelationship == 'same') {
            this.selectedSourceObject = this.selectedDisplayObject;
            this.selectedCommonParentObject = this.selectedDisplayObject;
            this.selectedDisplayRelationshipPath = 'Id';
            this.selectedSourceRelationshipPath = 'Id';
        }
    }

    handleSourceObjectChange(event) {
        const selectedObj = event.detail.value;
        console.log('selected value --> ' + selectedObj);
        this.selectedDisplayChildRelationship = selectedObj;

        // Get child object name based on child relationship
        const childObj = this.childObjects.find(obj => obj.childRelationshipName === selectedObj);
        console.log(JSON.stringify(childObj));
        this.selectedSourceObject = childObj.name;
        console.log('selected source obj --> ' + this.selectedSourceObject);

        if (this.selectedAncestorType == 'ancestor') {
            this.loadParentObjects();
        }
    }

    handleAncestorTypeChange(event) {
        this.selectedAncestorType = event.detail.value;
        console.log('ancestor type --> ', this.selectedAncestorType);
        if (this.selectedAncestorType == 'display') {
            console.log('is display --> ', this.selectedAncestorType);
            this.selectedDisplayRelationshipPath = 'Id';
            this.selectedCommonParentObject = this.selectedDisplayObject;
            console.log('selectedCommonParentObject --> ', this.selectedCommonParentObject);

            console.log('selectedDisplayObject --> ', this.selectedDisplayObject);
            console.log('selectedSourceObject --> ', this.selectedSourceObject);
            console.log('selectedDisplayChildRelationship --> ', this.selectedDisplayChildRelationship);

            findInverseRelationshipField({
                parentObjectName: this.selectedDisplayObject, 
                childObjectName: this.selectedSourceObject, 
                relationshipName: this.selectedDisplayChildRelationship
            })
            .then(result => {
                console.log('result of inverse method call --> ', result);
                this.selectedSourceRelationshipPath = result;
            })
            .catch(error => {
                console.error(error);
            });
            
        } else if (this.selectedAncestorType == 'ancestor') {
            console.log('is ancestor --> ', this.selectedAncestorType);
            this.loadParentObjects();
        }
    }

    handleCommonParentObjectChange(event) {
        const selectedObj = event.detail.value;
        console.log(selectedObj);
        this.selectedCommonParentObject = selectedObj;
        this.fetchRelationshipPaths();
    }

    handleSelectedDisplayPath(event) {
        console.log(event.detail.value);
        this.selectedDisplayRelationshipPath = event.detail.value;
    }

    handleSelectedSourcePath(event) {
        console.log(event.detail.value);
        this.selectedSourceRelationshipPath = event.detail.value;
    }

    loadChildObjects() {
        if (this.selectedDisplayObject) {
            getChildObjects({objName: this.selectedDisplayObject})
            .then(result => {
                this.childObjects = result;
                this.hasLoadedChildObjects = true;
            })
            .catch(error => {
                this.error = error;
                console.error(this.error);
            });
        }
    }

    loadParentObjects() {
        if (this.selectedDisplayObject && this.selectedSourceObject) {
            getCommonParentObjects({
                displayObject: this.selectedDisplayObject, 
                sourceObject: this.selectedSourceObject
            })
            .then(result => {
                this.commonAncestorObjects = result;
                this.hasLoadedCommonParents = true;
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
            commonParentApiName: this.selectedCommonParentObject
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
            console.log('relationship paths --> ', this.relationshipPaths);
            console.log('displayRelationshipPaths --> ', this.displayRelationshipPaths);
            console.log('sourceRelationshipPaths --> ', this.sourceRelationshipPaths);
        })
        .catch(error => {
            console.error('Error fetching relationship paths --> ', error);
        });
    }

    handleSave() {
        const fields = {};
        fields[NAME_FIELD.fieldApiName] = this.badgeDefinitionName;
        fields[DISPLAY_OBJ_FIELD.fieldApiName] = this.selectedDisplayObject;
        fields[SOURCE_OBJ_FIELD.fieldApiName] = this.selectedSourceObjectRelationship == 'same' ? this.selectedDisplayObject : this.selectedSourceObject;
        fields[ANCESTOR_OBJ_FIELD.fieldApiName] = this.selectedCommonParentObject;
        fields[DISPLAY_PATH_FIELD.fieldApiName] = this.selectedDisplayRelationshipPath;
        fields[SOURCE_PATH_FIELD.fieldApiName] = this.selectedSourceObjectRelationship == 'same' ? 'Id' : this.selectedSourceRelationshipPath;
        
        const recordInput = { apiName: BADGE_DEFINITION_OBJECT.objectApiName, fields };

        createRecord(recordInput)
            .then((badgeDef) => {
                this.badgeDefinitionId = badgeDef.id;
                this.resetForm();
                this.badgeDefinitionName = null;
                this.selectedDisplayObject = null;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "The Highlight Badge Definition was created",
                        variant: "success",
                    }),
                );
                // Open edit page for new definition
                this[NavigationMixin.Navigate]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: this.badgeDefinitionId,
                        actionName: "edit",
                    },
                });
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: error.body.message,
                        variant: "error",
                    }),
                );
            });
    }

    resetForm() {
        this.selectedSourceObject = null;
        this.selectedCommonParentObject = null;
        this.selectedSourceObjectRelationship = null;
        this.selectedDisplayChildRelationship = null;
        this.selectedAncestorType = null;
        this.hasLoadedChildObjects = false;
        this.hasLoadedCommonParents = false;
        this.hasLoadedRelationshipPaths = false;
        this.ancestorRelationshipPaths = null;
        this.displayRelationshipPaths = null;
        this.sourceRelationshipPaths = null;
        this.selectedDisplayRelationshipPath = null;
        this.selectedSourceRelationshipPath = null;
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