import { LightningElement, api, wire }      from 'lwc';
import { NavigationMixin }                   from 'lightning/navigation';
import { refreshApex }                       from '@salesforce/apex';
import { ShowToastEvent }                    from 'lightning/platformShowToastEvent';
import getPurchaseOrderFiles from '@salesforce/apex/PurchaseOrderFilesController.getPurchaseOrderFiles';
import togglePurchaseOrder   from '@salesforce/apex/PurchaseOrderFilesController.togglePurchaseOrder';

const ICON_MAP = {
    pdf:  'doctype:pdf',
    csv:  'doctype:csv',
    xlsx: 'doctype:excel',
    xls:  'doctype:excel',
    docx: 'doctype:word',
    doc:  'doctype:word',
    png:  'doctype:image',
    jpg:  'doctype:image',
    jpeg: 'doctype:image',
    gif:  'doctype:image',
    mp4:  'doctype:video',
    pptx: 'doctype:ppt',
    ppt:  'doctype:ppt',
    txt:  'doctype:txt',
    zip:  'doctype:zip'
};

// All Files: show first 5 rows initially
const ALL_FILES_PAGE_SIZE = 5;

const _refreshRegistry = new Set();

export default class PurchaseOrders extends NavigationMixin(LightningElement) {
    @api recordId;
    @api showAllFiles = false;
    @api sectionLabel = 'Purchase Orders';

    files             = [];
    isLoading         = false;
    isDownloading     = false;
    _allFilesExpanded = false;   // true after View All clicked on All Files list
    wiredResult;

    get filterByType()  { return !this.showAllFiles; }
    get titleColStyle() { return this.showAllFiles ? 'width:38%' : 'width:44%'; }
    get hasFiles()      { return this.files && this.files.length > 0; }
    get isEmpty()       { return !this.isLoading && !this.hasFiles; }
    get sectionTitle()  { return `${this.sectionLabel} (${this.files.length})`; }

    get showPOActions() {
        return !this.showAllFiles && this.files.length > 0;
    }

    get downloadLabel() {
        return this.isDownloading ? 'Downloading...' : 'Download All';
    }

    // All Files:
    //   - collapsed → first 5 rows
    //   - expanded  → all rows (with PO checkbox still visible)
    // PO list: always show all rows
    get visibleFiles() {
        if (this.showAllFiles) {
            return this._allFilesExpanded
                ? this.files
                : this.files.slice(0, ALL_FILES_PAGE_SIZE);
        }
        return this.files;
    }

    // All Files: "View All" shown when > 5 and not yet expanded
    get showAllFilesViewAll() {
        return this.showAllFiles
            && !this._allFilesExpanded
            && this.files.length > ALL_FILES_PAGE_SIZE;
    }

    // All Files: "Show Less" shown after expanding
    get showAllFilesShowLess() {
        return this.showAllFiles
            && this._allFilesExpanded
            && this.files.length > ALL_FILES_PAGE_SIZE;
    }

    // PO list: "View All" always shown when files exist
    // Navigates to standard Salesforce files page (no checkbox needed there)
    get showPOViewAll() {
        return !this.showAllFiles && this.files.length > 0;
    }

    connectedCallback()    { _refreshRegistry.add(this); }
    disconnectedCallback() { _refreshRegistry.delete(this); }

    _refreshAll() {
        _refreshRegistry.forEach((inst) => refreshApex(inst.wiredResult));
    }

    // ── Wire ──────────────────────────────────────────────────────
    @wire(getPurchaseOrderFiles, { recordId: '$recordId', filterByType: '$filterByType' })
    wiredFiles(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.files = data.map((f) => {
                const ext         = (f.fileExtension || '').toLowerCase();
                const suffix      = ext ? '.' + ext : '';
                const rawTitle    = f.title || '';
                const displayName = rawTitle
                    ? (rawTitle.toLowerCase().endsWith(suffix)
                        ? rawTitle : rawTitle + suffix)
                    : 'Untitled';
                return {
                    contentDocumentId : f.contentDocumentId,
                    contentVersionId  : f.contentVersionId,
                    displayName       : displayName,
                    ownerName         : f.ownerName        || '',
                    lastModifiedDate  : f.lastModifiedDate,
                    documentType      : f.documentType     || '',
                    downloadUrl       : f.downloadUrl      || '',
                    formattedSize     : this.formatSize(f.contentSize),
                    iconName          : ICON_MAP[ext]      || 'doctype:unknown',
                    isPurchaseOrder   : f.documentType === 'Purchase Order'
                };
            });
        } else if (error) {
            this.showToast('Error loading files', this.reduceError(error), 'error');
        }
    }

    // ── All Files: View All — expand in place, checkbox stays ─────
    handleViewAll() {
        if (this.showAllFiles) {
            // Expand the All Files list in place
            // User can still check/uncheck PO boxes on all files
            this._allFilesExpanded = true;
        } else {
            // PO list: navigate to standard Salesforce files page
            this[NavigationMixin.Navigate]({
                type      : 'standard__recordRelationshipPage',
                attributes: {
                    recordId            : this.recordId,
                    objectApiName       : 'Account',
                    relationshipApiName : 'AttachedContentDocuments',
                    actionName          : 'view'
                }
            });
        }
    }

    // ── All Files: Show Less — collapse back to 5 rows ────────────
    handleShowLess() {
        this._allFilesExpanded = false;
        this.template
            .querySelector('.po-panel')
            .scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    // ── Download All — Salesforce bulk zip endpoint ───────────────
    handleDownloadAll() {
        if (!this.files || this.files.length === 0 || this.isDownloading) return;

        const versionIds = this.files
            .map((f) => f.contentVersionId)
            .filter(Boolean);

        if (versionIds.length === 0) {
            this.showToast('Error', 'No version IDs found for download.', 'error');
            return;
        }

        this.isDownloading = true;

        // Single zip download — works for 100+ files
        const zipUrl = '/sfc/servlet.shepherd/version/download/'
            + versionIds.join('/');

        const a    = document.createElement('a');
        a.href     = zipUrl;
        a.download = 'PurchaseOrders.zip';
        a.style.display = 'none';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);

        this.showToast(
            'Download Started',
            `Downloading ${this.files.length} Purchase Order file(s) as a zip.`,
            'success'
        );

        this.isDownloading = false;
    }

    // ── PO Checkbox Toggle ────────────────────────────────────────
    handlePOToggle(event) {
        const contentDocumentId = event.currentTarget.dataset.id;
        const isChecked         = event.target.checked;

        this.files = this.files.map((f) =>
            f.contentDocumentId === contentDocumentId
                ? { ...f, isPurchaseOrder: isChecked }
                : f
        );

        togglePurchaseOrder({ contentDocumentId, isChecked })
            .then(() => {
                this.showToast(
                    'Success',
                    isChecked
                        ? 'File added to Purchase Orders.'
                        : 'File removed from Purchase Orders.',
                    'success'
                );
                this._refreshAll();
            })
            .catch((err) => {
                this.files = this.files.map((f) =>
                    f.contentDocumentId === contentDocumentId
                        ? { ...f, isPurchaseOrder: !isChecked }
                        : f
                );
                this.showToast('Error', this.reduceError(err), 'error');
            });
    }

    // ── Preview ───────────────────────────────────────────────────
    handleFilePreview(event) {
        event.preventDefault();
        const contentDocumentId = event.currentTarget.dataset.id;
        if (!contentDocumentId) return;
        this[NavigationMixin.Navigate]({
            type      : 'standard__namedPage',
            attributes: { pageName: 'filePreview' },
            state     : {
                recordIds       : contentDocumentId,
                selectedRecordId: contentDocumentId
            }
        });
    }

    // ── Helpers ───────────────────────────────────────────────────
    formatSize(bytes) {
        if (bytes == null) return '';
        if (bytes < 1024)    return `${bytes} B`;
        if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
        return `${(bytes / 1048576).toFixed(1)} MB`;
    }
    reduceError(err) {
        if (Array.isArray(err?.body))                          return err.body.map((e) => e.message).join(', ');
        if (err?.body && typeof err.body.message === 'string') return err.body.message;
        return err?.message || 'Unknown error';
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}