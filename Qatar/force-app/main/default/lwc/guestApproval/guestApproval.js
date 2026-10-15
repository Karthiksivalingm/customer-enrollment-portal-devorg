import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GUEST_LIST_OBJECT from '@salesforce/schema/Guest_List__c';
import getGuestList from '@salesforce/apex/GuestListRelatedListController.getGuestList';
import upsertHERequest from '@salesforce/apex/GuestListRelatedListController.upsertHERequest';

const PAGE_SIZE = 20;
const AVATAR_COLORS = [
    { bg: '#EEF2FF', text: '#4338CA' }, { bg: '#F0FDF4', text: '#16A34A' },
    { bg: '#FFF7ED', text: '#EA580C' }, { bg: '#FDF4FF', text: '#9333EA' },
    { bg: '#FFF1F2', text: '#E11D48' }, { bg: '#ECFEFF', text: '#0891B2' },
    { bg: '#FFFBEB', text: '#D97706' }, { bg: '#F0FDFA', text: '#0D9488' },
];

// Every column except Picture and HE Notes is filterable.
// type drives which operator set + input widget the filter row uses.
const FILTER_COLUMNS = [
    { value: 'contactExternalId', label: 'Contact ID',              type: 'text' },
    { value: 'title',             label: 'Title',                   type: 'text' },
    { value: 'contactName',       label: 'Name',                    type: 'text' },
    { value: 'biography',         label: 'Biography',                type: 'text' },
    { value: 'reasonForAttendance', label: 'Reason of Attendance',  type: 'text' },
    { value: 'source',            label: 'Source',                  type: 'text' },
    { value: 'protocolTier',      label: 'Protocol Tier',           type: 'text' },
    { value: 'guestCategory',     label: 'Guest Category',          type: 'text' },
    { value: 'guestSector',       label: 'Guest Sector',            type: 'text' },
    { value: 'company',           label: 'Company Affiliated',      type: 'text' },
    { value: 'jobTitle',          label: 'Job Title',                type: 'text' },
    { value: 'backgroundCheck',   label: 'Background Check',        type: 'text' },
    { value: 'rsvp',              label: 'RSVP Status',             type: 'text' },
    { value: 'inboundDateTime',   label: 'Inbound Date & Time',     type: 'datetime' },
    { value: 'outboundDateTime',  label: 'Outbound Date & Time',    type: 'datetime' },
    { value: 'hotelName',         label: 'Hotel Name',               type: 'text' },
    { value: 'invitedGuest',      label: '+1 of Invited Guest',     type: 'text' },
    { value: 'relationshipTo',    label: 'Relationship To',          type: 'text' },
    { value: 'escortedBy',        label: 'Escort',                   type: 'text' }
];

const TEXT_OPERATORS = [
    { value: 'contains',       label: 'Contains' },
    { value: 'equals',         label: 'Equals' },
    { value: 'notEquals',      label: 'Not Equal To' },
    { value: 'startsWith',     label: 'Starts With' },
    { value: 'doesNotContain', label: 'Does Not Contain' },
    { value: 'isBlank',        label: 'Is Blank' },
    { value: 'isNotBlank',     label: 'Is Not Blank' }
];

const DATETIME_OPERATORS = [
    { value: 'equals',     label: 'On' },
    { value: 'before',     label: 'Before' },
    { value: 'after',      label: 'After' },
    { value: 'between',    label: 'Between' },
    { value: 'isBlank',    label: 'Is Blank' },
    { value: 'isNotBlank', label: 'Is Not Blank' }
];

let filterIdCounter = 0;

export default class GuestListRelatedList extends NavigationMixin(LightningElement) {

    @api recordId;

    @track _allGuests    = [];
    @track searchTerm    = '';
    @track isLoading     = true;
    @track isLoadingMore = false;
    @track error         = false;
    @track totalCount    = 0;
    @track hasMore       = false;
    _offset              = 0;

    @track isPanelOpen          = false;
    @track activePanelGuestId   = null;
    @track activePanelGuestName = '';
    @track activePanelNote      = '';
    @track isSavingNote         = false;

    // ── New Guest modal (Contact__c + Guest_Tier_Recommendations__c only) ────
    @track isNewGuestModalOpen = false;
    @track isSavingNewGuest    = false;
    guestListObjectApiName     = GUEST_LIST_OBJECT;

    // ── Filter builder state ─────────────────────────────────────────────────
    @track isFilterPanelOpen = false;
    @track filters = []; // [{ id, field, operator, value, value2 }]

    // ── Grouping (main guest ▸ accompanying guest) state ──────────────────────
    // A child guest's Escorted_By__c lookup (returned as escortedById) points
    // at the main guest's Guest_List__c Id — the real relationship, same as
    // mainGuestId in the reference component. Dropdown defaults OPEN for every
    // main guest; a main guest's id lands in this set only after collapsing it.
    @track collapsedMainIds = new Set();

    connectedCallback() {
        this._loadRecords(false);
    }

    _loadRecords(append) {
        if (append) {
            this.isLoadingMore = true;
        } else {
            this.isLoading = true;
            this._allGuests = [];
            this._offset = 0;
        }

        getGuestList({
            invitationId : this.recordId,
            pageSize     : PAGE_SIZE,
            offset       : this._offset
        })
        .then(result => {
            this.error      = false;
            this.totalCount = result.totalCount;
            this.hasMore    = result.hasMore;

            const newRecords = (result.records || []).map((g, idx) => {
                const colorIdx   = this._hashColor(g.contactName || '');
                const c          = AVATAR_COLORS[colorIdx];
                const i          = this._offset + idx;
                return {
                    ...g,
                    rowNum      : i + 1,
                    rowClass    : i % 2 === 0 ? 'gl-row gl-row-even' : 'gl-row gl-row-odd',
                    rsvpClass   : this._rsvpClass(g.rsvp),
                    avatarStyle : 'background:' + c.bg + ';color:' + c.text + ';',
                    hasPhoto    : !!g.photoUrl
                };
            });

            this._allGuests  = append ? [...this._allGuests, ...newRecords] : newRecords;
            this._offset    += newRecords.length;
            this.isLoading   = false;
            this.isLoadingMore = false;
        })
        .catch(err => {
            this.error         = true;
            this.isLoading     = false;
            this.isLoadingMore = false;
            console.error('GuestListRelatedList error:', err);
        });
    }

    handleScroll(event) {
        if (this.isLoadingMore || !this.hasMore) return;
        const el = event.target;
        if (el.scrollTop + el.clientHeight >= el.scrollHeight - 100) {
            this._loadRecords(true);
        }
    }

    // ── Search + Filters combined (record-level match) ──────────────────────

    get _searchMatchedGuests() {
        if (!this.searchTerm) return this._allGuests;
        const term = this.searchTerm.toLowerCase();
        return this._allGuests.filter(g =>
            (g.contactExternalId   || '').toLowerCase().includes(term) ||
            (g.title                || '').toLowerCase().includes(term) ||
            (g.contactName          || '').toLowerCase().includes(term) ||
            (g.biography            || '').toLowerCase().includes(term) ||
            (g.reasonForAttendance  || '').toLowerCase().includes(term) ||
            (g.source               || '').toLowerCase().includes(term) ||
            (g.protocolTier         || '').toLowerCase().includes(term) ||
            (g.guestCategory        || '').toLowerCase().includes(term) ||
            (g.guestSector          || '').toLowerCase().includes(term) ||
            (g.company              || '').toLowerCase().includes(term) ||
            (g.jobTitle             || '').toLowerCase().includes(term) ||
            (g.backgroundCheck      || '').toLowerCase().includes(term) ||
            (g.rsvp                 || '').toLowerCase().includes(term) ||
            (g.inboundDateTime      || '').toLowerCase().includes(term) ||
            (g.outboundDateTime     || '').toLowerCase().includes(term) ||
            (g.hotelName            || '').toLowerCase().includes(term) ||
            (g.invitedGuest         || '').toLowerCase().includes(term) ||
            (g.relationshipTo       || '').toLowerCase().includes(term) ||
            (g.escortedBy           || '').toLowerCase().includes(term)
        );
    }

    get filteredGuests() {
        const base = this._searchMatchedGuests;
        const activeFilters = this.filters.filter(f => f.field && f.operator);
        if (!activeFilters.length) return base;
        return base.filter(g => this._matchesAllFilters(g, activeFilters));
    }

    // ── Main guest ▸ Accompanying guest grouping ─────────────────────────────
    // Real Id-based grouping: Main_Guest__c on a child guest record points at
    // the parent Guest_List__c Id (returned here as mainGuestId). A main guest
    // can have MANY children, so we group into arrays, not a single
    // overwritten value.
    get groupedRows() {
        const matchedIds = new Set(this.filteredGuests.map(g => g.id));

        const childIds = new Set();
        const childrenByMainId = new Map(); // mainId -> array of children
        this._allGuests.forEach(child => {
            const mainId = child.mainGuestId;
            if (!mainId || mainId === child.id || childIds.has(child.id)) return;
            childIds.add(child.id);
            if (!childrenByMainId.has(mainId)) childrenByMainId.set(mainId, []);
            childrenByMainId.get(mainId).push(child);
        });

        const rows = [];
        let displayIndex = 0;

        this._allGuests.forEach(main => {
            if (childIds.has(main.id)) return; // rendered nested under its main instead

            const children = childrenByMainId.get(main.id) || [];
            const mainMatches = matchedIds.has(main.id);
            const matchingChildren = children.filter(c => matchedIds.has(c.id));

            if (!mainMatches && matchingChildren.length === 0) return;

            displayIndex += 1;
            const hasChildren = children.length > 0;
            const isExpanded  = hasChildren && !this.collapsedMainIds.has(main.id);

            rows.push({
                ...main,
                rowNum: displayIndex,
                rowClass: displayIndex % 2 === 0 ? 'gl-row gl-row-even' : 'gl-row gl-row-odd',
                isMain: true,
                isDimmed: !mainMatches,
                hasChildren,
                isExpanded,
                chevronClass: `gl-chevron${isExpanded ? ' gl-chevron-open' : ''}`,
                accompanyingDisplay: children.map(c => c.contactName || '—').filter(Boolean).join(', ') || '—',
                guestTypeLabel: 'Main Guest',
                guestTypeClass: 'gl-guest-type-badge gl-guest-type-main'
            });

            if (isExpanded) {
                children.forEach(child => {
                    const childMatches = matchedIds.has(child.id);
                    displayIndex += 1;
                    rows.push({
                        ...child,
                        rowNum: displayIndex,
                        rowClass: `gl-row gl-row-child${displayIndex % 2 === 0 ? ' gl-row-even' : ' gl-row-odd'}`,
                        isMain: false,
                        isDimmed: !childMatches,
                        hasChildren: false,
                        chevronClass: '',
                        guestTypeLabel: 'Child Guest',
                        guestTypeClass: 'gl-guest-type-badge gl-guest-type-child'
                    });
                });
            }
        });

        return rows;
    }

    toggleMainExpand(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        const next = new Set(this.collapsedMainIds);
        if (next.has(id)) {
            next.delete(id);
        } else {
            next.add(id);
        }
        this.collapsedMainIds = next;
    }

    _matchesAllFilters(guest, activeFilters) {
        return activeFilters.every(f => this._matchesOneFilter(guest, f));
    }

    _matchesOneFilter(guest, f) {
        const col = FILTER_COLUMNS.find(c => c.value === f.field);
        if (!col) return true;
        const raw = guest[f.field];

        if (col.type === 'datetime') {
            return this._matchDateTime(raw, f);
        }
        return this._matchText(raw, f);
    }

    _matchText(raw, f) {
        if (f.operator === 'isBlank')    return !raw || !raw.toString().trim();
        if (f.operator === 'isNotBlank') return !!raw && !!raw.toString().trim();
        if (!f.value) return true; // incomplete filter row — don't exclude anything yet

        const val    = (raw || '').toString().toLowerCase().trim();
        const target = f.value.toLowerCase().trim();

        switch (f.operator) {
            case 'equals':         return val === target;
            case 'notEquals':      return val !== target;
            case 'contains':       return val.includes(target);
            case 'doesNotContain': return !val.includes(target);
            case 'startsWith':     return val.startsWith(target);
            default:                return true;
        }
    }

    _matchDateTime(raw, f) {
        const hasVal = !!raw;
        if (f.operator === 'isBlank')    return !hasVal;
        if (f.operator === 'isNotBlank') return hasVal;
        if (!hasVal) return false;

        const d = new Date(raw).getTime();
        if (Number.isNaN(d)) return false;

        switch (f.operator) {
            case 'equals': {
                if (!f.value) return true;
                return this._sameDay(d, new Date(f.value).getTime());
            }
            case 'before': {
                if (!f.value) return true;
                return d < new Date(f.value).getTime();
            }
            case 'after': {
                if (!f.value) return true;
                return d > new Date(f.value).getTime();
            }
            case 'between': {
                if (!f.value || !f.value2) return true;
                const start = new Date(f.value).getTime();
                const end   = new Date(f.value2).getTime();
                return d >= start && d <= end;
            }
            default: return true;
        }
    }

    _sameDay(a, b) {
        const da = new Date(a);
        const db = new Date(b);
        return da.getFullYear() === db.getFullYear()
            && da.getMonth()    === db.getMonth()
            && da.getDate()     === db.getDate();
    }

    get filteredCount()   { return this.filteredGuests.length; }
    get hasRecords()      { return !this.isLoading && !this.error && this._allGuests.length > 0; }
    get isEmpty()         { return !this.isLoading && !this.error && this._allGuests.length === 0; }
    get noSearchResults() { return (!!this.searchTerm || this.activeFilterCount > 0) && this.filteredGuests.length === 0; }
    get charCount()       { return (this.activePanelNote || '').length; }
    get loadedCount()     { return this._allGuests.length; }

    handleSearch(event) { this.searchTerm = event.target.value; }
    clearSearch()       { this.searchTerm = ''; }

    handleNavigation(event) {
        event.preventDefault();
        const id = event.currentTarget.dataset.id;
        if (!id) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: id, actionName: 'view' }
        });
    }

    handleNew() {
        this.isNewGuestModalOpen = true;
    }

    closeNewGuestModal() {
        this.isNewGuestModalOpen = false;
        this.isSavingNewGuest    = false;
    }

    handleNewGuestSubmit(event) {
        event.preventDefault();
        this.isSavingNewGuest = true;
        const fields = { ...event.detail.fields, Invitation__c: this.recordId };
        this.template.querySelector('lightning-record-edit-form.gl-new-guest-form').submit(fields);
    }

    handleNewGuestSuccess() {
        this.isSavingNewGuest    = false;
        this.isNewGuestModalOpen = false;
        this._toast('Success', 'Guest created successfully.', 'success');
        this._loadRecords(false);
    }

    handleNewGuestError(event) {
        this.isSavingNewGuest = false;
        console.error('New guest create error:', event.detail);
        const message = (event.detail && event.detail.message) || 'Failed to create guest. Please try again.';
        this._toast('Error', message, 'error');
    }

    openNotePanel(event) {
        const btn = event.currentTarget;
        this.activePanelGuestId   = btn.dataset.id;
        this.activePanelGuestName = btn.dataset.name;
        this.activePanelNote      = btn.dataset.note || '';
        this.isPanelOpen          = true;
    }

    closeNotePanel() {
        this.isPanelOpen          = false;
        this.activePanelGuestId   = null;
        this.activePanelGuestName = '';
        this.activePanelNote      = '';
    }

    handlePanelNoteChange(event) { this.activePanelNote = event.target.value; }

    handlePanelSave() {
        if (!this.activePanelNote || !this.activePanelNote.trim()) {
            this._toast('Warning', 'Please enter a note before saving.', 'warning');
            return;
        }
        this.isSavingNote = true;
        const guest = this._allGuests.find(g => g.id === this.activePanelGuestId);
        upsertHERequest({
            guestListId  : this.activePanelGuestId,
            guestName    : guest ? guest.contactName : 'Unknown',
            feedbackNote : this.activePanelNote
        })
        .then(() => {
            const savedNote = this.activePanelNote;
            const savedId   = this.activePanelGuestId;
            this._allGuests = this._allGuests.map(g =>
                g.id === savedId ? { ...g, heNote: savedNote } : g
            );
            this.isSavingNote = false;
            this.closeNotePanel();
            this._toast('Success', 'HE Request saved successfully.', 'success');
        })
        .catch(err => {
            console.error('upsertHERequest error:', err);
            this.isSavingNote = false;
            this._toast('Error', 'Failed to save. Please try again.', 'error');
        });
    }

    // ── Filter panel handlers ────────────────────────────────────────────────

    get filterColumnOptions() { return FILTER_COLUMNS; }

    get activeFilterCount() {
        return this.filters.filter(f => f.field && f.operator).length;
    }

    get hasActiveFilters() { return this.activeFilterCount > 0; }

    get hasNoFilterRows() { return this.filters.length === 0; }

    get filterButtonClass() {
        return `gl-filter-btn${this.hasActiveFilters ? ' gl-filter-btn-active' : ''}`;
    }

    get displayFilters() {
        return this.filters.map(f => {
            const col = FILTER_COLUMNS.find(c => c.value === f.field);
            const type = col ? col.type : 'text';
            const operatorOptions = type === 'datetime' ? DATETIME_OPERATORS : TEXT_OPERATORS;
            const isNoValueOp = f.operator === 'isBlank' || f.operator === 'isNotBlank';
            const isBetween    = type === 'datetime' && f.operator === 'between';

            return {
                ...f,
                columnType: type,
                operatorOptionsForSelect: operatorOptions.map(op => ({
                    ...op,
                    selected: op.value === f.operator
                })),
                columnOptionsForSelect: FILTER_COLUMNS.map(c => ({
                    ...c,
                    selected: c.value === f.field
                })),
                showValueInput: !isNoValueOp && type === 'text',
                showDateInput: !isNoValueOp && type === 'datetime' && !isBetween,
                showDateRangeInputs: isBetween,
                showNoValueHint: isNoValueOp,
                operatorDisabled: !f.field
            };
        });
    }

    toggleFilterPanel() {
        this.isFilterPanelOpen = !this.isFilterPanelOpen;
    }

    closeFilterPanel() {
        this.isFilterPanelOpen = false;
    }

    addFilterRow() {
        filterIdCounter += 1;
        this.filters = [
            ...this.filters,
            { id: `f${filterIdCounter}`, field: '', operator: '', value: '', value2: '' }
        ];
    }

    removeFilterRow(event) {
        const id = event.currentTarget.dataset.id;
        this.filters = this.filters.filter(f => f.id !== id);
    }

    clearAllFilters() {
        this.filters = [];
    }

    handleFilterFieldChange(event) {
        const id    = event.currentTarget.dataset.id;
        const value = event.target.value;
        this.filters = this.filters.map(f =>
            f.id === id ? { ...f, field: value, operator: '', value: '', value2: '' } : f
        );
    }

    handleFilterOperatorChange(event) {
        const id    = event.currentTarget.dataset.id;
        const value = event.target.value;
        this.filters = this.filters.map(f =>
            f.id === id ? { ...f, operator: value, value: '', value2: '' } : f
        );
    }

    handleFilterValueChange(event) {
        const id    = event.currentTarget.dataset.id;
        const value = event.target.value;
        this.filters = this.filters.map(f =>
            f.id === id ? { ...f, value } : f
        );
    }

    handleFilterValue2Change(event) {
        const id    = event.currentTarget.dataset.id;
        const value = event.target.value;
        this.filters = this.filters.map(f =>
            f.id === id ? { ...f, value2: value } : f
        );
    }

    _rsvpClass(rsvp) {
        const base = 'gl-rsvp ';
        if (!rsvp) return base + 'gl-rsvp-default';
        const v = rsvp.toLowerCase();
        if (v === 'accepted' || v === 'confirmed') return base + 'gl-rsvp-accepted';
        if (v === 'declined')                       return base + 'gl-rsvp-declined';
        if (v === 'pending')                        return base + 'gl-rsvp-pending';
        return base + 'gl-rsvp-default';
    }

    _hashColor(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) hash = str.charCodeAt(i) + ((hash << 5) - hash);
        return Math.abs(hash) % AVATAR_COLORS.length;
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}