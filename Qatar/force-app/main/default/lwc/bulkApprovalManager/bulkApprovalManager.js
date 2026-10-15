import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPendingApprovals from '@salesforce/apex/BulkApprovalController.getPendingApprovals';
import processBulkApprovals from '@salesforce/apex/BulkApprovalController.processBulkApprovals';

const PAGE_SIZE     = 50;
const PREVIEW_LIMIT = 5;

const AVATAR_COLORS = [
    { bg: '#EEF2FF', text: '#4338CA' },
    { bg: '#F0FDF4', text: '#16A34A' },
    { bg: '#FFF7ED', text: '#EA580C' },
    { bg: '#FDF4FF', text: '#9333EA' },
    { bg: '#FFF1F2', text: '#E11D48' },
    { bg: '#ECFEFF', text: '#0891B2' },
    { bg: '#FFFBEB', text: '#D97706' },
    { bg: '#F0FDFA', text: '#0D9488' },
];

export default class BulkApprovalManager extends NavigationMixin(LightningElement) {

    @track allRecords      = [];
    @track filteredRecords = [];
    @track visibleRecords  = [];
    @track visibleStage1Records = [];
    @track visibleStage2Records = [];
    @track selectedIds     = new Set();
    @track actionIds       = [];
    @track isLoading       = false;
    @track isProcessing    = false;
    @track hasError        = false;
    @track errorMessage    = '';
    @track searchTerm      = '';
    @track bulkComment     = '';
    @track currentPage     = 1;
    @track sortAsc         = false;

    // Guest Tier Recommendation edits (Stage 2 only) keyed by workItemId,
    // pushed to Guest_Tiers__c on Approve
    @track guestTierEdits  = {};

    guestTierOptions = [
        { label: 'Local',                      value: 'Local' },
        { label: 'International Hosted',       value: 'International Hosted' },
        { label: 'International Non-Hosted',   value: 'International Non-Hosted' },
    ];

    // Confirm modal
    @track showConfirmModal = false;
    @track pendingAction    = '';

    // Detail modal
    @track showDetailModal = false;
    @track detailRecord    = null;

    // Toast
    @track showToast    = false;
    @track toastTitle   = '';
    @track toastMessage = '';
    @track toastType    = 'success';
    toastTimer          = null;

    connectedCallback() {
        this.loadApprovals();
    }

    loadApprovals() {
        this.isLoading   = true;
        this.hasError    = false;
        this.selectedIds = new Set();
        this.currentPage = 1;

        getPendingApprovals()
            .then(data => {
                this.allRecords = this._processRecords(data || []);
                this._applyFilters();
                this.isLoading = false;
            })
            .catch(err => {
                this.hasError     = true;
                this.errorMessage = err?.body?.message || 'Failed to load approvals.';
                this.isLoading    = false;
            });
    }

    _processRecords(raw) {
        return raw.map(r => {
            const avatarName = r.contactName || r.submittedByName || '';
            const colorIdx   = this._hashColor(avatarName);
            const c          = AVATAR_COLORS[colorIdx];
            const stage      = r.approvalStage || 1;
            return {
                ...r,
                contactInitial  : avatarName ? avatarName.charAt(0).toUpperCase() : '?',
                avatarStyle     : 'background:' + c.bg + ';color:' + c.text + ';',
                relativeTime    : this._relativeTime(r.createdDate),
                recordUrl       : '/lightning/r/' + r.targetObjectId + '/view',
                isSelected      : false,
                rowClass        : 'bam-row',
                approvalStage   : stage,
                stageBadgeClass : stage === 1 ? 'bam-stage-badge bam-stage-1' : 'bam-stage-badge bam-stage-2',
                isStage1        : stage === 1,
                approveTitle    : stage === 1 ? 'Review' : 'Approve',
                heRequestsDisplay : (r.detail && r.detail.heRequests && r.detail.heRequests.length > 0)
                    ? r.detail.heRequests.join(', ') : '—',
            };
        });
    }

    _applyFilters() {
        let records = [...this.allRecords];

        if (this.searchTerm) {
            const term = this.searchTerm.toLowerCase();
            records = records.filter(r =>
                (r.submittedByName  || '').toLowerCase().includes(term) ||
                (r.targetObjectName || '').toLowerCase().includes(term) ||
                (r.contactName      || '').toLowerCase().includes(term) ||
                (r.eventName        || '').toLowerCase().includes(term) ||
                (r.sessionName      || '').toLowerCase().includes(term)
            );
        }

        const mul = this.sortAsc ? 1 : -1;
        records = records.slice().sort((a, b) =>
            mul * (new Date(a.createdDate) - new Date(b.createdDate))
        );

        records = records.map(r => ({
            ...r,
            isSelected : this.selectedIds.has(r.workItemId),
            rowClass   : this.selectedIds.has(r.workItemId) ? 'bam-row bam-row-selected' : 'bam-row',
        }));

        this.filteredRecords = records;
        this._paginate();
    }

    _paginate() {
        const visible = this.filteredRecords.slice(0, this.currentPage * PAGE_SIZE);
        this.visibleRecords        = visible;
        this.visibleStage1Records  = visible.filter(r => r.approvalStage === 1);
        this.visibleStage2Records  = visible.filter(r => r.approvalStage === 2);
    }

    // ─── Getters ─────────────────────────────────────────────────────────────
    get hasRecords()    { return this.allRecords.length > 0 && !this.isLoading; }
    get showEmpty()     { return !this.isLoading && !this.hasError && this.allRecords.length === 0; }
    get showTable()     { return !this.isLoading && !this.hasError && this.allRecords.length > 0; }
    get totalCount()    { return this.allRecords.length; }
    get filteredCount() { return this.filteredRecords.length; }
    get selectedCount() { return this.selectedIds.size; }
    get showActionBar() { return this.selectedIds.size > 0; }

    get hasStage1Records() { return this.visibleStage1Records.length > 0; }
    get hasStage2Records() { return this.visibleStage2Records.length > 0; }
    get stage1Count()      { return this.filteredRecords.filter(r => r.approvalStage === 1).length; }
    get stage2Count()      { return this.filteredRecords.filter(r => r.approvalStage === 2).length; }

    // True if ALL selected records are stage 1
    get selectedAllStage1() {
        if (this.selectedIds.size === 0) return false;
        return this.allRecords
            .filter(r => this.selectedIds.has(r.workItemId))
            .every(r => r.approvalStage === 1);
    }

    get approveAllLabel() { return this.selectedAllStage1 ? 'Review All' : 'Approve All'; }
    get showBulkReject()  { return !this.selectedAllStage1; }

    // True if ALL action records (in the confirm modal) are stage 1
    get isActionStage1() {
        if (!this.actionIds || this.actionIds.length === 0) return false;
        return this.allRecords
            .filter(r => this.actionIds.includes(r.workItemId))
            .every(r => r.approvalStage === 1);
    }

    // For confirm modal title
    get approveLabel() {
        return (this.actionIds.length === 1
            ? this.allRecords.find(r => r.workItemId === this.actionIds[0])
            : null)?.approvalStage === 1 ? 'Review' : 'Approve';
    }

    get allSelected() {
        return this.filteredRecords.length > 0 &&
               this.filteredRecords.every(r => this.selectedIds.has(r.workItemId));
    }

    get hasMoreRecords()  { return this.visibleRecords.length < this.filteredRecords.length; }
    get remainingCount()  { return this.filteredRecords.length - this.visibleRecords.length; }
    get showVirtualInfo() { return this.filteredRecords.length > PAGE_SIZE; }
    get visibleRangeText(){ return '1–' + this.visibleRecords.length + ' of ' + this.filteredRecords.length; }
    get selectedRecordLabel() { return this.selectedIds.size === 1 ? 'Record' : 'Records'; }

    get sortDateClass() { return 'bam-sort-btn bam-sort-active'; }
    get sortedByDate()  { return true; }
    get sortIconDate()  { return this.sortAsc ? 'utility:arrowup' : 'utility:arrowdown'; }

    // Detail modal getters
    get isStage1() { return this.detailRecord && this.detailRecord.approvalStage === 1; }
    get isStage2() { return this.detailRecord && this.detailRecord.approvalStage === 2; }
    get detailApproveLabel() { return this.isStage1 ? 'Review' : 'Approve'; }
    get detailHasData() { return this.detailRecord && this.detailRecord.detail != null; }
    get detailHasHeRequests() {
        return this.detailRecord &&
               this.detailRecord.detail &&
               this.detailRecord.detail.heRequests &&
               this.detailRecord.detail.heRequests.length > 0;
    }

    // Confirm modal getters
    get modalTitle() {
        const n = this.actionIds ? this.actionIds.length : 0;
        if (this.pendingAction === 'Approve') {
            const verb = this.isActionStage1 ? 'Review' : 'Approve';
            return verb + ' ' + n + (n === 1 ? ' Request' : ' Requests');
        }
        return 'Reject ' + n + (n === 1 ? ' Request' : ' Requests');
    }
    get modalSubtitle() {
        const n = this.actionIds ? this.actionIds.length : 0;
        return n + ' approval request' + (n === 1 ? '' : 's');
    }
    get modalDescription() {
        const n = this.actionIds ? this.actionIds.length : 0;
        if (this.pendingAction === 'Approve') {
            if (this.isActionStage1)
                return 'You are about to mark ' + n + (n === 1 ? ' request' : ' requests') + ' as reviewed. This action cannot be undone.';
            return 'You are about to approve ' + n + (n === 1 ? ' request.' : ' requests.') + ' This action cannot be undone.';
        }
        return 'You are about to reject ' + n + (n === 1 ? ' request.' : ' requests.') + ' Submitters will be notified.';
    }
    get modalIcon()         { return this.pendingAction === 'Approve' ? 'utility:check' : 'utility:close'; }
    get modalConfirmLabel() {
        if (this.pendingAction === 'Approve') return this.isActionStage1 ? 'Yes, Mark as Reviewed' : 'Yes, Approve';
        return 'Yes, Reject';
    }
    get modalHeaderStyle() {
        return this.pendingAction === 'Approve'
            ? 'background:linear-gradient(135deg,#059669,#10B981);'
            : 'background:linear-gradient(135deg,#DC2626,#EF4444);';
    }
    get modalConfirmStyle() {
        return this.pendingAction === 'Approve'
            ? 'background:#059669;color:#fff;border:none;'
            : 'background:#DC2626;color:#fff;border:none;';
    }
    get selectedPreviewRecords() {
        if (!this.actionIds || this.actionIds.length === 0) return [];
        return this.allRecords
            .filter(r => this.actionIds.includes(r.workItemId))
            .slice(0, PREVIEW_LIMIT);
    }
    get hasMoreSelectedRecords() { return this.actionIds && this.actionIds.length > PREVIEW_LIMIT; }
    get moreSelectedCount()      { return this.actionIds ? this.actionIds.length - PREVIEW_LIMIT : 0; }

    get toastIcon()    { return ({ success:'utility:success', error:'utility:error', warning:'utility:warning' })[this.toastType] || 'utility:info'; }
    get toastVariant() { return this.toastType; }
    get toastStyle()   { return 'border-left:4px solid ' + (({ success:'#059669', error:'#DC2626', warning:'#D97706' })[this.toastType] || '#3B82F6') + ';'; }

    // ─── Handlers ────────────────────────────────────────────────────────────
    handleSearch(event) {
        this.searchTerm  = event.target.value;
        this.currentPage = 1;
        this._applyFilters();
    }

    sortByDate() {
        this.sortAsc = !this.sortAsc;
        this._applyFilters();
    }

    handleSelectAll(event) {
        if (event.target.checked) {
            this.filteredRecords.forEach(r => this.selectedIds.add(r.workItemId));
        } else {
            this.selectedIds = new Set();
        }
        this._applyFilters();
    }

    handleRowSelect(event) {
        const id = event.target.dataset.id;
        if (event.target.checked) {
            this.selectedIds.add(id);
        } else {
            this.selectedIds.delete(id);
        }
        this._applyFilters();
    }

    clearSelection() {
        this.selectedIds = new Set();
        this._applyFilters();
    }

    handleCommentChange(event) {
        this.bulkComment = event.target.value;
    }

    // Guest Tier Recommendation is editable only on Stage 2 rows.
    handleGuestTierChange(event) {
        const id    = event.target.dataset.id;
        const value = event.detail.value;

        this.guestTierEdits = { ...this.guestTierEdits, [id]: value };

        const record = this.allRecords.find(r => r.workItemId === id);
        if (record && record.detail) {
            record.detail.guestTierRecommendation = value;
        }
        this._applyFilters();
    }

    handleScroll(event) {
        const el = event.target;
        if (el.scrollTop + el.clientHeight >= el.scrollHeight - 100 && this.hasMoreRecords) {
            this.loadMoreRecords();
        }
    }

    loadMoreRecords() {
        this.currentPage++;
        this._paginate();
    }

    // ── Detail modal ──────────────────────────────────────────────────────────
    handleOpenDetail(event) {
        const id = event.currentTarget.dataset.id;
        const record = this.allRecords.find(r => r.workItemId === id);
        if (record) {
            this.detailRecord    = record;
            this.showDetailModal = true;
        }
    }

    closeDetailModal() {
        this.showDetailModal = false;
        this.detailRecord    = null;
    }

    handleMainGuestClick(event) {
        const id = event.currentTarget.dataset.id;
        if (!id) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: id, actionName: 'view' }
        });
    }

    handleDetailApprove() {
        this.actionIds       = [this.detailRecord.workItemId];
        this.showDetailModal = false;
        this.pendingAction   = 'Approve';
        this.showConfirmModal = true;
    }

    handleDetailReject() {
        this.actionIds       = [this.detailRecord.workItemId];
        this.showDetailModal = false;
        this.pendingAction   = 'Reject';
        this.showConfirmModal = true;
    }

    // ── Quick row actions ─────────────────────────────────────────────────────
    handleQuickApprove(event) {
        this.actionIds        = [event.currentTarget.dataset.id];
        this.pendingAction    = 'Approve';
        this.showConfirmModal = true;
    }

    handleQuickReject(event) {
        this.actionIds        = [event.currentTarget.dataset.id];
        this.pendingAction    = 'Reject';
        this.showConfirmModal = true;
    }

    // ── Bulk actions ──────────────────────────────────────────────────────────
    handleBulkApprove(event) {
        event.preventDefault();
        event.stopPropagation();
        this.actionIds        = [...this.selectedIds];
        this.pendingAction    = 'Approve';
        this.showConfirmModal = true;
    }

    handleBulkReject(event) {
        event.preventDefault();
        event.stopPropagation();
        this.actionIds        = [...this.selectedIds];
        this.pendingAction    = 'Reject';
        this.showConfirmModal = true;
    }

    closeModal() {
        this.showConfirmModal = false;
        this.pendingAction    = '';
        this.bulkComment      = '';
        this.actionIds        = [];
    }

    handleBackdropClick() { this.closeModal(); }
    stopPropagation(event) { event.stopPropagation(); }

    confirmAction() {
        if (!this.pendingAction || this.isProcessing) return;
        if (!this.actionIds || this.actionIds.length === 0) return;
        this.isProcessing = true;

        const ids = [...this.actionIds];
        const isStage1Action = this.isActionStage1; // capture before actionIds is cleared

        // Only Approve actions push edited Guest Tier Recommendation values
        // (Stage 2 only) to Guest_Tiers__c; the server only approves a work
        // item once that push has succeeded.
        const guestTierUpdates = {};
        if (this.pendingAction === 'Approve') {
            ids.forEach(id => {
                const record = this.allRecords.find(r => r.workItemId === id);
                if (!record || record.approvalStage !== 2) return; // tier only applies to Stage 2

                if (Object.prototype.hasOwnProperty.call(this.guestTierEdits, id)) {
                    // User explicitly changed it in this session
                    guestTierUpdates[id] = this.guestTierEdits[id];
                } else if (record.detail && record.detail.guestTierRecommendation) {
                    // User left it as-is — still send the current value so it's persisted
                    guestTierUpdates[id] = record.detail.guestTierRecommendation;
                }
            });
        }

        processBulkApprovals({
            workItemIds : ids,
            action      : this.pendingAction,
            comments    : this.bulkComment || '',
            guestTierUpdates : guestTierUpdates,
        })
        .then(result => {
            this.isProcessing     = false;
            this.showConfirmModal = false;
            this.bulkComment      = '';
            this.actionIds        = [];
            this.selectedIds      = new Set();

            const remainingEdits = { ...this.guestTierEdits };
            ids.forEach(id => { delete remainingEdits[id]; });
            this.guestTierEdits = remainingEdits;

            if (result.failureCount === 0) {
                const actionVerb   = (this.pendingAction === 'Approve' && isStage1Action) ? 'Review' : this.pendingAction;
                const pastVerb     = (this.pendingAction === 'Approve' && isStage1Action) ? 'Reviewed' : this.pendingAction + 'd';
                const pastVerbLower = pastVerb.toLowerCase();
                this._showToast('success',
                    actionVerb + 'ed Successfully',
                    result.successCount + (result.successCount === 1 ? ' request ' : ' requests ') + pastVerbLower + '.'
                );
            } else if (result.successCount > 0) {
                this._showToast('warning', 'Partial Success',
                    result.successCount + ' succeeded, ' + result.failureCount + ' failed. ' + (result.errors[0] || '')
                );
            } else {
                this._showToast('error', (this.pendingAction === 'Approve' && isStage1Action ? 'Review' : this.pendingAction) + ' Failed', result.errors.join(' | '));
            }

            setTimeout(() => { window.location.reload(); }, 1500);
        })
        .catch(err => {
            this.isProcessing     = false;
            this.showConfirmModal = false;
            this._showToast('error', 'Action Failed', err?.body?.message || 'An unexpected error occurred.');
        });
    }

    _showToast(type, title, message) {
        if (this.toastTimer) clearTimeout(this.toastTimer);
        this.toastType    = type;
        this.toastTitle   = title;
        this.toastMessage = message;
        this.showToast    = true;
        this.toastTimer   = setTimeout(() => { this.showToast = false; }, 5000);
    }

    closeToast() {
        this.showToast = false;
        if (this.toastTimer) clearTimeout(this.toastTimer);
    }

    _hashColor(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
        }
        return Math.abs(hash) % AVATAR_COLORS.length;
    }

    _relativeTime(dateStr) {
        if (!dateStr) return '';
        const diff = Math.floor((new Date() - new Date(dateStr)) / 1000);
        if (diff < 60)     return 'Just now';
        if (diff < 3600)   return Math.floor(diff / 60) + 'm ago';
        if (diff < 86400)  return Math.floor(diff / 3600) + 'h ago';
        if (diff < 604800) return Math.floor(diff / 86400) + 'd ago';
        return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
}