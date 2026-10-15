import { LightningElement, track } from 'lwc';
import getObjects                from '@salesforce/apex/NotificationController.getObjects';
import getFields                 from '@salesforce/apex/NotificationController.getFields';
import getPicklistValues         from '@salesforce/apex/NotificationController.getPicklistValues';
import getAccountName            from '@salesforce/apex/NotificationController.getAccountName';
import getContactName            from '@salesforce/apex/NotificationController.getContactName';
import getEmailTemplateFolders   from '@salesforce/apex/NotificationController.getEmailTemplateFolders';
import saveAll                   from '@salesforce/apex/NotificationController.saveAll';
import loadAll                   from '@salesforce/apex/NotificationController.loadAll';
import removeAccountNotification from '@salesforce/apex/NotificationController.removeAccountNotification';
import removeContactNotification from '@salesforce/apex/NotificationController.removeContactNotification';

export default class NotificationCenter extends LightningElement {

    // ── User Level ──────────────────────────────────────────────────────
    @track disableAllEmails = false;

    // ── Account Level ────────────────────────────────────────────────────
    @track selectedAccounts = [];

    accountDisplayInfo = {
        primaryField    : 'Name',
        additionalFields: ['Phone']
    };
    accountMatchingInfo = {
        primaryField: { fieldPath: 'Name' }
    };

    // ── Contact Level ────────────────────────────────────────────────────
    @track selectedContacts = [];
    @track folderOptions    = [];   // [{label, value}] loaded from Apex

    contactDisplayInfo = {
        primaryField    : 'Name',
        additionalFields: ['Email']
    };
    contactMatchingInfo = {
        primaryField: { fieldPath: 'Name' }
    };

    // ── Field Level ──────────────────────────────────────────────────────
    @track objectOptions   = [];
    @track fieldOptions    = [];
    @track valueOptions    = [];
    @track rules           = [];

    @track selectedObject   = '';
    @track selectedField    = '';
    @track fieldValue       = '';
    @track isPicklistField  = false;

    @track isLoadingObjects = false;
    @track isLoadingFields  = false;

    // ── UI State ─────────────────────────────────────────────────────────
    @track isSaving     = false;
    @track saveSuccess  = false;
    @track errorMessage = '';

    // ── Lifecycle ─────────────────────────────────────────────────────────

    connectedCallback() {
        this.loadData();
        this.loadObjects();
        this.loadFolders();
    }

    // ── Load helpers ──────────────────────────────────────────────────────

    loadData() {
        loadAll()
            .then(res => {
                this.disableAllEmails = res.disableAll;

                this.selectedAccounts = (res.accounts || []).map(a => ({
                    ...a,
                    toggleLabel: a.disableEmail ? 'Disabled' : 'Enabled'
                }));

                this.selectedContacts = (res.contacts || []).map(c => ({
                    ...c,
                    toggleLabel     : c.disableEmail ? 'Disabled' : 'Enabled',
                    suppressedFolders: c.suppressedFolders || '',
                    showFolderPicker : false
                }));

                this.rules = (res.rules || []).map(r => ({ ...r }));
            })
            .catch(err => {
                this.errorMessage = 'Failed to load settings: ' + this.extractError(err);
            });
    }

    loadObjects() {
        this.isLoadingObjects = true;
        getObjects()
            .then(res => { this.objectOptions = res; })
            .catch(err => {
                this.errorMessage = 'Failed to load objects: ' + this.extractError(err);
            })
            .finally(() => { this.isLoadingObjects = false; });
    }

    loadFolders() {
        getEmailTemplateFolders()
            .then(res => { this.folderOptions = res; })
            .catch(err => {
                this.errorMessage = 'Failed to load email template folders: ' + this.extractError(err);
            });
    }

    // ── User Level handlers ───────────────────────────────────────────────

    handleUserChange(event) {
        this.disableAllEmails = event.target.checked;
        this.clearStatus();
    }

    // ── Account Level handlers ────────────────────────────────────────────

    handleAccountSelect(event) {
        const recordId = event.detail.recordId;
        if (!recordId) return;

        if (this.selectedAccounts.some(a => a.Id === recordId)) {
            this.clearAccountPicker();
            return;
        }

        this.selectedAccounts = [
            ...this.selectedAccounts,
            { Id: recordId, Name: 'Loading...', disableEmail: true, toggleLabel: 'Disabled' }
        ];
        this.clearAccountPicker();
        this.clearStatus();

        getAccountName({ accountId: recordId })
            .then(name => {
                this.selectedAccounts = this.selectedAccounts.map(a =>
                    a.Id === recordId ? { ...a, Name: name } : a
                );
            })
            .catch(() => {
                this.selectedAccounts = this.selectedAccounts.map(a =>
                    a.Id === recordId ? { ...a, Name: recordId } : a
                );
            });
    }

    handleAccountToggle(event) {
        const id      = event.target.dataset.id;
        const checked = event.target.checked;

        if (!checked) {
            this.selectedAccounts = this.selectedAccounts.filter(a => a.Id !== id);
            removeAccountNotification({ accountId: id })
                .catch(err => {
                    this.errorMessage = 'Failed to remove company: ' + this.extractError(err);
                });
        } else {
            this.selectedAccounts = this.selectedAccounts.map(acc =>
                acc.Id === id
                    ? { ...acc, disableEmail: true, toggleLabel: 'Disabled' }
                    : acc
            );
        }
        this.clearStatus();
    }

    handleRemoveAccount(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedAccounts = this.selectedAccounts.filter(a => a.Id !== id);
        this.clearStatus();
    }

    // ── Contact Level handlers ────────────────────────────────────────────

    handleContactSelect(event) {
        const recordId = event.detail.recordId;
        if (!recordId) return;

        if (this.selectedContacts.some(c => c.Id === recordId)) {
            this.clearContactPicker();
            return;
        }

        this.selectedContacts = [
            ...this.selectedContacts,
            {
                Id               : recordId,
                Name             : 'Loading...',
                disableEmail     : true,
                toggleLabel      : 'Disabled',
                suppressedFolders: '',      // empty = suppress ALL
                showFolderPicker : false
            }
        ];
        this.clearContactPicker();
        this.clearStatus();

        getContactName({ contactId: recordId })
            .then(name => {
                this.selectedContacts = this.selectedContacts.map(c =>
                    c.Id === recordId ? { ...c, Name: name } : c
                );
            })
            .catch(() => {
                this.selectedContacts = this.selectedContacts.map(c =>
                    c.Id === recordId ? { ...c, Name: recordId } : c
                );
            });
    }

    handleContactToggle(event) {
        const id      = event.target.dataset.id;
        const checked = event.target.checked;

        if (!checked) {
            this.selectedContacts = this.selectedContacts.filter(c => c.Id !== id);
            removeContactNotification({ contactId: id })
                .catch(err => {
                    this.errorMessage = 'Failed to remove contact: ' + this.extractError(err);
                });
        } else {
            this.selectedContacts = this.selectedContacts.map(con =>
                con.Id === id
                    ? { ...con, disableEmail: true, toggleLabel: 'Disabled' }
                    : con
            );
        }
        this.clearStatus();
    }

    handleRemoveContact(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedContacts = this.selectedContacts.filter(c => c.Id !== id);
        this.clearStatus();
    }

    // Toggle the folder picker panel open/close for a specific contact row
    handleToggleFolderPicker(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedContacts = this.selectedContacts.map(c =>
            c.Id === id ? { ...c, showFolderPicker: !c.showFolderPicker } : c
        );
    }

    // When user picks/unpicks folders in the dual-listbox
    handleFolderChange(event) {
        const id     = event.currentTarget.dataset.id;
        const chosen = event.detail.value; // array of selected DeveloperNames
        const joined = chosen.join(',');

        this.selectedContacts = this.selectedContacts.map(c =>
            c.Id === id
                ? { ...c, suppressedFolders: joined }
                : c
        );
        this.clearStatus();
    }

    // ── Field Level handlers ──────────────────────────────────────────────

    handleObjectChange(event) {
        this.selectedObject  = event.detail.value;
        this.selectedField   = '';
        this.fieldValue      = '';
        this.fieldOptions    = [];
        this.valueOptions    = [];
        this.isPicklistField = false;
        this.isLoadingFields = true;

        getFields({ objectName: this.selectedObject })
            .then(res => { this.fieldOptions = res; })
            .catch(err => {
                this.errorMessage = 'Failed to load fields: ' + this.extractError(err);
            })
            .finally(() => { this.isLoadingFields = false; });

        this.clearStatus();
    }

    handleFieldChange(event) {
        this.selectedField   = event.detail.value;
        this.fieldValue      = '';
        this.valueOptions    = [];
        this.isPicklistField = false;

        const fieldMeta = this.fieldOptions.find(f => f.value === this.selectedField);
        if (fieldMeta && fieldMeta.isPicklist) {
            getPicklistValues({
                objectName: this.selectedObject,
                fieldName : this.selectedField
            })
                .then(res => {
                    this.valueOptions    = res;
                    this.isPicklistField = res.length > 0;
                })
                .catch(err => {
                    this.errorMessage = 'Failed to load picklist values: ' + this.extractError(err);
                });
        }

        this.clearStatus();
    }

    handleValueChange(event) {
        this.fieldValue = event.detail ? event.detail.value : event.target.value;
        this.clearStatus();
    }

    handleAddRule() {
        if (!this.selectedObject || !this.selectedField || !this.fieldValue) return;

        const objectLabel = this.objectOptions.find(o => o.value === this.selectedObject)?.label || this.selectedObject;
        const fieldLabel  = this.fieldOptions.find(f => f.value === this.selectedField)?.label   || this.selectedField;

        this.rules = [
            ...this.rules,
            {
                id         : `rule_${Date.now()}`,
                objectName : this.selectedObject,
                objectLabel,
                fieldName  : this.selectedField,
                fieldLabel,
                value      : this.fieldValue
            }
        ];

        this.selectedField   = '';
        this.fieldValue      = '';
        this.isPicklistField = false;
        this.valueOptions    = [];

        this.clearStatus();
    }

    handleRemoveRule(event) {
        const id = event.currentTarget.dataset.id;
        this.rules = this.rules.filter(r => r.id !== id);
        this.clearStatus();
    }

    // ── Save ──────────────────────────────────────────────────────────────

    handleSave() {
        this.isSaving     = true;
        this.saveSuccess  = false;
        this.errorMessage = '';

        const accountsPayload = this.selectedAccounts.map(a => ({
            Id          : a.Id,
            Name        : a.Name,
            disableEmail: a.disableEmail
        }));

        const contactsPayload = this.selectedContacts.map(c => ({
            Id               : c.Id,
            Name             : c.Name,
            disableEmail     : c.disableEmail,
            suppressedFolders: c.suppressedFolders || ''
        }));

        const rulesPayload = this.rules.map(r => ({
            objectName: r.objectName,
            fieldName : r.fieldName,
            value     : r.value
        }));

        saveAll({
            disableAll  : this.disableAllEmails,
            accountsJson: JSON.stringify(accountsPayload),
            contactsJson: JSON.stringify(contactsPayload),
            rulesJson   : JSON.stringify(rulesPayload)
        })
            .then(() => {
                this.saveSuccess = true;
                setTimeout(() => { window.location.reload(); }, 1500);
            })
            .catch(err => {
                this.errorMessage = 'Save failed: ' + this.extractError(err);
            })
            .finally(() => { this.isSaving = false; });
    }

    // ── Computed getters ──────────────────────────────────────────────────

    get hasAccounts() { return this.selectedAccounts.length > 0; }
    get hasContacts() { return this.selectedContacts.length > 0; }
    get hasRules()    { return this.rules.length > 0; }

    get isFieldDisabled()   { return !this.selectedObject || this.isLoadingFields; }
    get isValueDisabled()   { return !this.selectedField; }
    get isAddRuleDisabled() { return !this.selectedObject || !this.selectedField || !this.fieldValue; }

    // Enriches each contact with computed display properties for the template
    get selectedContactsWithFolders() {
        return this.selectedContacts.map(c => {
            const folderArr = c.suppressedFolders
                ? c.suppressedFolders.split(',').filter(f => f.trim() !== '')
                : [];

            const folderSummary = folderArr.length === 0
                ? 'All emails suppressed'
                : folderArr.length + ' folder(s) selected';

            return {
                ...c,
                selectedFolderValues: folderArr,
                folderSummary
            };
        });
    }

    // ── Private helpers ───────────────────────────────────────────────────

    clearStatus() {
        this.saveSuccess  = false;
        this.errorMessage = '';
    }

    clearAccountPicker() {
        const picker = this.template.querySelector('lightning-record-picker[object-api-name="Account"]');
        if (picker) picker.clearSelection();
    }

    clearContactPicker() {
        const picker = this.template.querySelector('lightning-record-picker[object-api-name="Contact"]');
        if (picker) picker.clearSelection();
    }

    extractError(err) {
        if (err?.body?.message) return err.body.message;
        if (err?.message)       return err.message;
        return JSON.stringify(err);
    }
}