import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getReportByInvitation from '@salesforce/apex/GuestCategoryReportController.getReportByInvitation';

const COLUMNS = [
    { key: 'photoUrl', label: 'Photo', isPhoto: true },
    { key: 'title', label: 'Title' },
    { key: 'fullName', label: 'Full Name' },
    { key: 'bio', label: 'Biography', wrap: true },
    { key: 'reasonForAttendance', label: 'Reason of Attendance' },
    { key: 'source', label: 'Guest Source' },
    { key: 'tier', label: 'Tier' },
    { key: 'guestCategory', label: 'Guest Category' },
    { key: 'company', label: 'Company Affiliated' },
    { key: 'jobTitle', label: 'Job Title' },
    { key: 'inboundDate', label: 'Inbound Date' },
    { key: 'inboundTime', label: 'Inbound Time' },
    { key: 'outboundDate', label: 'Outbound Date' },
    { key: 'outboundTime', label: 'Outbound Time' },
    { key: 'accompanyingGuest', label: 'Accompanying Guest' },
    { key: 'relationshipTo', label: 'Relationship to' },
];

const PAGE_SIZE = 25;
const ALL_SENTINEL = 'ALL';

export default class GuestInvitationReport extends NavigationMixin(LightningElement) {
    eventId;
    tier;
    invitationStatus;

    eventName;
    guestTier;
    invitationStatusLabel;
    reportGeneratedDate;

    allGuests = [];
    visibleCount = PAGE_SIZE;

    columns = COLUMNS;

    isLoaded = false;
    error;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            const newEventId = pageRef.state.c__eventId;
            const newTier = pageRef.state.c__tier;
            const newStatus = pageRef.state.c__invitationStatus;
            if (newEventId !== this.eventId || newTier !== this.tier || newStatus !== this.invitationStatus) {
                this.eventId = newEventId;
                this.tier = newTier;
                this.invitationStatus = newStatus;
                this.loadReport();
            }
        }
    }

    get isGenerateAll() {
        return this.tier === ALL_SENTINEL || this.invitationStatus === ALL_SENTINEL;
    }

    loadReport() {
        if (!this.eventId) {
            return;
        }
        // If not "generate all", we still require both filters to be present
        if (!this.isGenerateAll && (!this.tier || !this.invitationStatus)) {
            return;
        }

        this.isLoaded = false;
        this.visibleCount = PAGE_SIZE;

        const tierParam = (!this.tier || this.tier === ALL_SENTINEL) ? null : this.tier;
        const statusParam = (!this.invitationStatus || this.invitationStatus === ALL_SENTINEL) ? null : this.invitationStatus;

        getReportByInvitation({
            eventId: this.eventId,
            guestTier: tierParam,
            invitationStatus: statusParam
        })
            .then((data) => {
                this.eventName = data.eventName;
                this.guestTier = tierParam ? data.guestTier : 'All Tiers';
                this.invitationStatusLabel = statusParam ? data.registrationStatus : 'All Statuses';
                this.reportGeneratedDate = new Date().toLocaleString();
                this.allGuests = data.guests.map((g, idx) => ({
                    key: idx,
                    cells: COLUMNS.map((col) => ({
                        key: col.key + idx,
                        value: g[col.key],
                        isPhoto: !!col.isPhoto,
                        cssClass: col.isPhoto ? 'cell photo-cell' : (col.wrap ? 'cell wrap-cell' : 'cell nowrap-cell')
                    }))
                }));
                this.error = undefined;
                this.isLoaded = true;
            })
            .catch((err) => {
                this.error = err.body ? err.body.message : err.message;
                this.isLoaded = true;
            });
    }

    get hasError() {
        return !!this.error;
    }

    get showTable() {
        return this.isLoaded && !this.error;
    }

    get guestCount() {
        return this.allGuests.length;
    }

    get guests() {
        return this.allGuests.slice(0, this.visibleCount);
    }

    get hasMore() {
        return this.visibleCount < this.allGuests.length;
    }

    handleLoadMore() {
        this.visibleCount += PAGE_SIZE;
    }

    handleTableScroll(event) {
        const el = event.target;
        const nearBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 100;
        if (nearBottom && this.hasMore) {
            this.handleLoadMore();
        }
    }

    handleDownloadPdf() {
        const url =
            '/apex/GuestInvitationReportPdf' +
            `?eventId=${encodeURIComponent(this.eventId)}` +
            `&tier=${encodeURIComponent(this.tier || ALL_SENTINEL)}` +
            `&status=${encodeURIComponent(this.invitationStatus || ALL_SENTINEL)}`;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: { url }
        }).then((resolvedUrl) => {
            window.open(resolvedUrl, '_blank');
        });
    }
}