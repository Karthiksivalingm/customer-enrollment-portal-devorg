import { LightningElement, api, track } from 'lwc';
import { NavigationMixin }               from 'lightning/navigation';

import getGuestLists     from '@salesforce/apex/GuestListInvitationController.getGuestLists';
import submitForApproval from '@salesforce/apex/GuestListInvitationController.submitForApproval';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const GROUPS_PER_PAGE = 20;
const SEARCH_DEBOUNCE_MS = 250;

export default class GuestListInvitationApproval extends NavigationMixin(LightningElement) {

    @api recordId;

    showModal    = false;
    isLoading    = false;
    isSubmitting = false;

    _allRecords = [];
    _selectedIdSet = new Set();
    _expandedKeys = new Set();
    _submittingGroupKey = null;
    _searchDebounceHandle = null;

    searchTerm  = '';
    currentPage = 1;

    _groupsCache    = null;
    _groupsCacheKey = '';

    // ── getters (core) ───────────────────────────────────────────────────────

    get hasNoRecords()  { return !this.isLoading && this._allRecords.length === 0; }
    get hasRecords()    { return this._allRecords.length > 0; }
    get selectedCount() { return this._selectedIdSet.size; }
    get hasSelection()  { return this._selectedIdSet.size > 0; }
    get totalCount()    { return this._allRecords.filter(r => r.isActionable).length; }

    get filteredRecords() {
        if (!this.searchTerm) return this._allRecords;
        const t = this.searchTerm.toLowerCase();
        return this._allRecords.filter(r =>
            (r.recordName      || '').toLowerCase().includes(t) ||
            (r.contactName     || '').toLowerCase().includes(t) ||
            (r.invitationName  || '').toLowerCase().includes(t) ||
            (r.titleC          || '').toLowerCase().includes(t) ||
            (r.reasonC         || '').toLowerCase().includes(t)
        );
    }

    get allGroups() {
        const cacheKey = [
            this._allRecords.length,
            this.searchTerm,
            this._selectedIdSet.size,
            [...this._selectedIdSet].join(','),
            [...this._expandedKeys].join(','),
            this.isSubmitting,
            this._submittingGroupKey
        ].join('|');

        if (this._groupsCache && this._groupsCacheKey === cacheKey) {
            return this._groupsCache;
        }

        const mains = [];
        const childrenByParent = new Map();

        this.filteredRecords.forEach(r => {
            if (r.mainGuestId) {
                const arr = childrenByParent.get(r.mainGuestId) || [];
                arr.push(r);
                childrenByParent.set(r.mainGuestId, arr);
            } else {
                mains.push(r);
            }
        });

        mains.sort((a, b) =>
            (a.contactName || a.recordName || '').localeCompare(b.contactName || b.recordName || '')
        );

        const groups = mains.map((main, idx) => {
            const children     = childrenByParent.get(main.id) || [];
            const total        = children.length;
            const displayName  = main.contactName || main.recordName || `Guest ${String(main.id).slice(-6)}`;
            const initials     = this._initials(displayName);
            const mainSelected = main.isActionable && this._selectedIdSet.has(main.id);

            const mappedChildren = children.map(c => {
                const childDisplayName = c.contactName || c.recordName || `Guest ${String(c.id).slice(-6)}`;
                const isSel = c.isActionable && this._selectedIdSet.has(c.id);
                return {
                    ...c,
                    displayContactName: childDisplayName,
                    isSelected: isSel,
                    rowClass: `child-row${isSel ? ' is-selected' : ''}`,
                    hasStatus: !!c.statusLabel,
                    rowDisabled: this.isSubmitting
                };
            });

            const checkedIds = mappedChildren.filter(c => c.isSelected).map(c => c.id);
            if (mainSelected) checkedIds.push(main.id);

            const expanded = this._expandedKeys.has(main.id) && total > 0;

            return {
                key: main.id,
                rowKey: `grp-${idx}-${main.id}`,
                mainId: main.id,
                mainGuestName: displayName,
                recordLabel: main.recordName,
                mainIsActionable: main.isActionable,
                mainIsSelected: mainSelected,
                mainHasStatus: !!main.statusLabel,
                mainStatusLabel: main.statusLabel,
                mainSubmitDisabled: this.isSubmitting,
                initials,
                hasAccompanying: total > 0,
                childCount: total,
                groupStatusText: total === 0
                    ? (main.isActionable ? 'No accompanying guests' : 'Read-only — no accompanying guests')
                    : `${total} accompanying guest${total > 1 ? 's' : ''}`,
                isExpanded: expanded,
                cardClass: `guest-card${expanded ? ' is-expanded' : ''}${checkedIds.length > 0 ? ' has-selection' : ''}${main.isActionable ? '' : ' is-readonly-main'}`,
                chevronClass: `chevron-icon${expanded ? ' is-open' : ''}`,
                avatarClass: `avatar-ring avatar-${idx % 6}${main.isActionable ? '' : ' avatar-muted'}`,
                checkedCount: checkedIds.length,
                checkedIds,
                cardSubmitDisabled: this.isSubmitting || checkedIds.length === 0,
                isCardSubmitting: this._submittingGroupKey === main.id,
                children: mappedChildren
            };
        });

        this._groupsCache    = groups;
        this._groupsCacheKey = cacheKey;
        return groups;
    }

    get totalGroupCount() { return this.allGroups.length; }
    get totalPages()      { return Math.max(1, Math.ceil(this.totalGroupCount / GROUPS_PER_PAGE)); }

    get groupedPageRecords() {
        const page  = Math.min(this.currentPage, this.totalPages);
        const start = (page - 1) * GROUPS_PER_PAGE;
        return this.allGroups.slice(start, start + GROUPS_PER_PAGE);
    }

    get groupCount() { return this.groupedPageRecords.length; }
    get hasGroups()  { return this.groupCount > 0; }

    get totalFilteredCount() { return this.totalGroupCount; }

    get submitDisabled()  { return this.isSubmitting || !this._selectedIdSet.size; }
    get cancelDisabled()  { return this.isSubmitting; }
    get isPrevDisabled()  { return this.currentPage <= 1 || this.isSubmitting; }
    get isNextDisabled()  { return this.currentPage >= this.totalPages || this.isSubmitting; }
    get showPagination()  { return this.totalPages > 1; }

    get pageInfo() {
        if (!this.totalGroupCount) return 'No results';
        return `Page ${this.currentPage} of ${this.totalPages}`;
    }

    get selectionSummary() {
        const n = this._selectedIdSet.size;
        return n ? `${n} guest${n > 1 ? 's' : ''} selected` : '';
    }

    // ── Select All (page) ────────────────────────────────────────────────────

    get _pageActionableIds() {
        const ids = [];
        this.groupedPageRecords.forEach(g => {
            if (g.mainIsActionable) ids.push(g.mainId);
            g.children.forEach(c => { if (c.isActionable) ids.push(c.id); });
        });
        return ids;
    }

    get isPageFullySelected() {
        const ids = this._pageActionableIds;
        return ids.length > 0 && ids.every(id => this._selectedIdSet.has(id));
    }

    get selectPageLabel() {
        return this.isPageFullySelected ? 'Deselect Page' : 'Select Page';
    }

    get selectPageDisabled() {
        return this.isSubmitting || this._pageActionableIds.length === 0;
    }

    toggleSelectPage() {
        const ids = this._pageActionableIds;
        const shouldSelect = !this.isPageFullySelected;
        ids.forEach(id => {
            if (shouldSelect) {
                this._selectedIdSet.add(id);
            } else {
                this._selectedIdSet.delete(id);
            }
        });
        this._selectedIdSet = new Set(this._selectedIdSet);
    }

    // ── Select All (every actionable record matching current search, all pages) ─

    get _allMatchingActionableIds() {
        return this.filteredRecords.filter(r => r.isActionable).map(r => r.id);
    }

    get isAllMatchingSelected() {
        const ids = this._allMatchingActionableIds;
        return ids.length > 0 && ids.every(id => this._selectedIdSet.has(id));
    }

    get selectAllLabel() {
        return this.isAllMatchingSelected ? 'Deselect All' : 'Select All';
    }

    get selectAllDisabled() {
        return this.isSubmitting || this._allMatchingActionableIds.length === 0;
    }

    toggleSelectAllMatching() {
        const ids = this._allMatchingActionableIds;
        const shouldSelect = !this.isAllMatchingSelected;
        if (shouldSelect) {
            ids.forEach(id => this._selectedIdSet.add(id));
        } else {
            ids.forEach(id => this._selectedIdSet.delete(id));
        }
        this._selectedIdSet = new Set(this._selectedIdSet);
    }

    _initials(name) {
        if (!name) return '?';
        const parts = name.trim().split(/\s+/).filter(Boolean);
        if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }

    _refreshPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:   this.recordId,
                actionName: 'view'
            }
        });
    }

    openModal() {
        this.isLoading = true;
        this.showModal = true;

        getGuestLists({ invitationId: this.recordId })
            .then(data => {
                this._allRecords     = data || [];
                this._selectedIdSet  = new Set();
                this._expandedKeys   = new Set();
                this.currentPage     = 1;
                this.searchTerm      = '';
                this._groupsCache    = null;
                this._groupsCacheKey = '';
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title:   'Error loading records',
                    message: error.body ? error.body.message : JSON.stringify(error),
                    variant: 'error',
                    mode:    'sticky'
                }));
                this.showModal = false;
            })
            .finally(() => { this.isLoading = false; });
    }

    closeModal() {
        if (this.isSubmitting) return;
        window.clearTimeout(this._searchDebounceHandle);
        this.showModal        = false;
        this._selectedIdSet   = new Set();
        this._expandedKeys    = new Set();
        this._allRecords      = [];
        this.searchTerm       = '';
        this.currentPage      = 1;
        this._groupsCache     = null;
        this._groupsCacheKey  = '';
    }

    handleBackdropClick() { this.closeModal(); }

    handleSearch(event) {
        const value = event.target.value;
        window.clearTimeout(this._searchDebounceHandle);
        this._searchDebounceHandle = window.setTimeout(() => {
            this.searchTerm  = value;
            this.currentPage = 1;
        }, SEARCH_DEBOUNCE_MS);
    }

    handleClearSearch() {
        window.clearTimeout(this._searchDebounceHandle);
        this.searchTerm  = '';
        this.currentPage = 1;
    }

    handlePrev() {
        if (this.currentPage > 1) { this.currentPage--; }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) { this.currentPage++; }
    }

    submitSelected() {
        if (!this._selectedIdSet.size) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No records selected', message: 'Please check at least one guest.', variant: 'warning'
            }));
            return;
        }

        this.isSubmitting = true;
        const count = this._selectedIdSet.size;

        submitForApproval({ guestListIds: [...this._selectedIdSet] })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title:   'Submitted!',
                    message: `${count} guest(s) sent for approval.`,
                    variant: 'success'
                }));
                this.closeModal();
                this._refreshPage();
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title:   'Submission Error',
                    message: error.body ? error.body.message : JSON.stringify(error),
                    variant: 'error',
                    mode:    'sticky'
                }));
            })
            .finally(() => { this.isSubmitting = false; });
    }

    // ── expand / collapse — single card only, no "expand all" ───────────────

    toggleGroupExpand(event) {
        const key = event.currentTarget.dataset.key;
        if (this._expandedKeys.has(key)) {
            this._expandedKeys.delete(key);
        } else {
            this._expandedKeys.add(key);
        }
        this._expandedKeys = new Set(this._expandedKeys);
    }

    // ── checkbox selection — main and child share the same toggle ───────────

    toggleRowSelection(event) {
        const id = event.currentTarget.dataset.id;
        if (this._selectedIdSet.has(id)) {
            this._selectedIdSet.delete(id);
        } else {
            this._selectedIdSet.add(id);
        }
        this._selectedIdSet = new Set(this._selectedIdSet);
    }

    // ── per-row quick submit (bypasses checkboxes entirely) ─────────────────

    quickSubmit(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        if (!id || this.isSubmitting) return;

        this.isSubmitting = true;

        submitForApproval({ guestListIds: [id] })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title:   'Submitted!',
                    message: '1 guest sent for approval.',
                    variant: 'success'
                }));
                this.closeModal();
                this._refreshPage();
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title:   'Submission Error',
                    message: error.body ? error.body.message : JSON.stringify(error),
                    variant: 'error',
                    mode:    'sticky'
                }));
            })
            .finally(() => { this.isSubmitting = false; });
    }

    // ── per-card "Submit Selected" — only the CHECKED main + CHECKED children ─

    submitCheckedInGroup(event) {
        event.stopPropagation();
        const key   = event.currentTarget.dataset.key;
        const group = this.groupedPageRecords.find(g => g.key === key);
        const ids   = group ? group.checkedIds : [];

        if (!ids.length || this.isSubmitting) return;

        this.isSubmitting        = true;
        this._submittingGroupKey = key;
        const count = ids.length;

        submitForApproval({ guestListIds: ids })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title:   'Submitted!',
                    message: `${count} guest(s) sent for approval.`,
                    variant: 'success'
                }));
                this.closeModal();
                this._refreshPage();
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title:   'Submission Error',
                    message: error.body ? error.body.message : JSON.stringify(error),
                    variant: 'error',
                    mode:    'sticky'
                }));
            })
            .finally(() => {
                this.isSubmitting        = false;
                this._submittingGroupKey = null;
            });
    }
}