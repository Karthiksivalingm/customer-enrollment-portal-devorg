import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getReport from '@salesforce/apex/GuestCategoryReportController.getReport';
import getPdfBase64 from '@salesforce/apex/GuestCategoryReportPdfController.getPdfBase64';

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

export default class GuestCategoryReport extends LightningElement {
    eventId;
    tier;
    status;

    eventName;
    guestTier;
    registrationStatus;
    reportGeneratedDate;

    allGuests = [];
    visibleCount = PAGE_SIZE;

    columns = COLUMNS;

    isLoaded = false;
    isGeneratingPdf = false;
    error;
    pdfError;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            const newEventId = pageRef.state.c__eventId;
            const newTier = pageRef.state.c__tier;
            const newStatus = pageRef.state.c__status;
            if (newEventId !== this.eventId || newTier !== this.tier || newStatus !== this.status) {
                this.eventId = newEventId;
                this.tier = newTier;
                this.status = newStatus;
                this.loadReport();
            }
        }
    }

    get isGenerateAll() {
        return this.tier === ALL_SENTINEL || this.status === ALL_SENTINEL;
    }

    loadReport() {
        if (!this.eventId) {
            return;
        }
        // If not "generate all", we still require both filters to be present
        if (!this.isGenerateAll && (!this.tier || !this.status)) {
            return;
        }

        this.isLoaded = false;
        this.visibleCount = PAGE_SIZE;

        const tierParam = (!this.tier || this.tier === ALL_SENTINEL) ? null : this.tier;
        const statusParam = (!this.status || this.status === ALL_SENTINEL) ? null : this.status;

        getReport({ eventId: this.eventId, guestTier: tierParam, registrationStatus: statusParam })
            .then((data) => {
                this.eventName = data.eventName;
                this.guestTier = tierParam ? data.guestTier : 'All Tiers';
                this.registrationStatus = statusParam ? data.registrationStatus : 'All Statuses';
                // Report date reflects when the report was generated/viewed, not the event date.
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

    get hasPdfError() {
        return !!this.pdfError;
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

    get remainingCount() {
        return this.allGuests.length - this.visibleCount;
    }

    handleLoadMore() {
        this.visibleCount += PAGE_SIZE;
    }

    // Auto-load the next page as the user scrolls near the bottom of the table container.
    handleTableScroll(event) {
        const el = event.target;
        const nearBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 100;
        if (nearBottom && this.hasMore) {
            this.handleLoadMore();
        }
    }

    // Calls Apex directly and waits for the finished PDF bytes, instead of just
    // building a URL and opening a tab — GenerateUrl resolves almost instantly
    // regardless of how long the PDF actually takes to render server-side, so the
    // old approach's spinner (there wasn't even one here before) would've cleared
    // long before the report was ready. This way isGeneratingPdf accurately covers
    // the real generation time, and the button triggers an actual file download.
    handleDownloadPdf() {
        this.isGeneratingPdf = true;
        this.pdfError = undefined;

        getPdfBase64({
            eventId: this.eventId,
            tier: this.tier || ALL_SENTINEL,
            status: this.status || ALL_SENTINEL
        })
            .then((base64Pdf) => {
                const blob = this.base64ToPdfBlob(base64Pdf);
                const blobUrl = URL.createObjectURL(blob);
                const fileName = `${this.eventName || 'Guest_Category_Report'}.pdf`;

                const link = document.createElement('a');
                link.href = blobUrl;
                link.download = fileName;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                URL.revokeObjectURL(blobUrl);
            })
            .catch((err) => {
                this.pdfError = err.body ? err.body.message : err.message;
            })
            .finally(() => {
                this.isGeneratingPdf = false;
            });
    }

    // Decodes in small chunks rather than one giant array — safer for larger PDFs
    // (many guests / many photos) than converting the whole base64 string in one pass.
    base64ToPdfBlob(base64) {
        const byteCharacters = atob(base64);
        const chunkSize = 1024;
        const byteArrays = [];

        for (let offset = 0; offset < byteCharacters.length; offset += chunkSize) {
            const slice = byteCharacters.slice(offset, offset + chunkSize);
            const byteNumbers = new Array(slice.length);
            for (let i = 0; i < slice.length; i++) {
                byteNumbers[i] = slice.charCodeAt(i);
            }
            byteArrays.push(new Uint8Array(byteNumbers));
        }

        return new Blob(byteArrays, { type: 'application/pdf' });
    }
}