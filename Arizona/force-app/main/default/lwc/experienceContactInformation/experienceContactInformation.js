import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMyContact from '@salesforce/apex/ExperienceUserProfileController.getMyContact';

import FIRST_NAME from '@salesforce/schema/Contact.FirstName';
import MIDDLE_NAME from '@salesforce/schema/Contact.MiddleName';
import LAST_NAME from '@salesforce/schema/Contact.LastName';
import PREFERRED_CONTACT_METHOD from '@salesforce/schema/Contact.Preferred_Contact_Method__c';
import PREFERRED_LANGUAGE from '@salesforce/schema/Contact.Preferred_Language__c';
import DIVISION from '@salesforce/schema/Contact.Division__c';
import DRIVING_STATUS from '@salesforce/schema/Contact.Driving_Status__c';
import CONTRACT_TYPE from '@salesforce/schema/Contact.Contract_Type__c';
import LIVING_STATUS from '@salesforce/schema/Contact.Living_Status__c';
import MAILING_STREET from '@salesforce/schema/Contact.MailingStreet';
import MAILING_CITY from '@salesforce/schema/Contact.MailingCity';
import MAILING_STATE from '@salesforce/schema/Contact.MailingState';
import MAILING_POSTAL_CODE from '@salesforce/schema/Contact.MailingPostalCode';
import MAILING_COUNTRY from '@salesforce/schema/Contact.MailingCountry';
import MOBILE_PHONE from '@salesforce/schema/Contact.MobilePhone';
import EMAIL from '@salesforce/schema/Contact.Email';
import BIRTHDATE from '@salesforce/schema/Contact.Birthdate';
import SERVICE from '@salesforce/schema/Contact.Service__c';

export default class ExperienceContactInformation extends LightningElement {
    isLoading = false;
    contactId;
    fullName = '';
    firstName = '';
    lastName = '';
    birthdate;
    preferredLanguage = 'en'; // Default to English
    wiredContactResult;

    fields = {
        firstName: FIRST_NAME,
        middleName: MIDDLE_NAME,
        lastName: LAST_NAME,
        preferredContactMethod: PREFERRED_CONTACT_METHOD,
        preferredLanguage: PREFERRED_LANGUAGE,
        division: DIVISION,
        drivingStatus: DRIVING_STATUS,
        contractType: CONTRACT_TYPE,
        livingStatus: LIVING_STATUS,
        mailingStreet: MAILING_STREET,
        mailingCity: MAILING_CITY,
        mailingState: MAILING_STATE,
        mailingPostalCode: MAILING_POSTAL_CODE,
        mailingCountry: MAILING_COUNTRY,
        mobilePhone: MOBILE_PHONE,
        email: EMAIL,
        birthdate: BIRTHDATE,
        service: SERVICE
    };

    // Translation labels
    labels = {
        en: {
            cardTitle: 'Contact Information',
            firstName: 'First Name',
            middleName: 'Middle Name',
            lastName: 'Last Name',
            fullName: 'Full Name',
            preferredContactMethod: 'Preferred Contact Method',
            preferredLanguage: 'Preferred Language',
            division: 'Division',
            drivingStatus: 'Driving Status',
            contractType: 'Contract Type',
            livingStatus: 'Living Status',
            address: 'Address',
            mobile: 'Mobile',
            email: 'Email',
            dob: 'DOB',
            service: 'Service',
            error: 'Error',
            errorMessage: 'Failed to load contact information'
        },
        es: {
            cardTitle: 'Información de Contacto',
            firstName: 'Nombre',
            middleName: 'Segundo Nombre',
            lastName: 'Apellido',
            fullName: 'Nombre Completo',
            preferredContactMethod: 'Método Preferido de Contacto',
            preferredLanguage: 'Idioma Preferido',
            division: 'División',
            drivingStatus: 'Estado de Conducción',
            contractType: 'Tipo de Contrato',
            livingStatus: 'Estado de Vivienda',
            address: 'Dirección',
            mobile: 'Móvil',
            email: 'Correo Electrónico',
            dob: 'Fecha de Nacimiento',
            service: 'Servicio',
            error: 'Error',
            errorMessage: 'No se pudo cargar la información de contacto'
        }
    };

    @wire(getMyContact)
    wiredContact(result) {
        this.wiredContactResult = result;
        const { data, error } = result;

        if (data) {
            this.contactId = data.Id;
            this.fullName = data.Name;
            this.firstName = data.FirstName;
            this.lastName = data.LastName;
            this.birthdate = data.Birthdate;

            // Set language preference from contact
            if (data.Preferred_Language__c) {
                this.preferredLanguage = data.Preferred_Language__c.toLowerCase().startsWith('es') ? 'es' : 'en';
            }
        } else if (error) {
            this.showToast(this.currentLabel('error'), this.reduceError(error), 'error');
        }
    }

    get cardTitle() {
        return this.currentLabel('cardTitle');
    }

    // Get current language labels
    currentLabel(key) {
        return this.labels[this.preferredLanguage]?.[key] || this.labels['en'][key];
    }

    // Helper method to get all labels for the template
    get currentLabels() {
        return this.labels[this.preferredLanguage] || this.labels['en'];
    }

    // NEW - initials shown in the profile avatar circle (e.g. "UT" for
    // First="UT", Last="EC" -> "UE"; falls back to a single "?" if
    // neither name part has loaded yet).
    get initials() {
        const firstInitial = this.firstName ? this.firstName.trim().charAt(0) : '';
        const lastInitial = this.lastName ? this.lastName.trim().charAt(0) : '';
        const combined = `${firstInitial}${lastInitial}`.toUpperCase();
        return combined || '?';
    }

    // Full Name formatted by language convention:
    // en: "First Last" | es: "Last, First"
    get formattedFullName() {
        if (!this.firstName && !this.lastName) {
            return this.fullName || '';
        }
        return this.preferredLanguage === 'es'
            ? `${this.lastName || ''}, ${this.firstName || ''}`.trim()
            : `${this.firstName || ''} ${this.lastName || ''}`.trim();
    }

    // Locale string passed to lightning-formatted-date-time
    // en: en-US (MM/DD/YYYY) | es: es-ES (DD/MM/YYYY)
    get dateLocale() {
        return this.preferredLanguage === 'es' ? 'es-ES' : 'en-US';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }

        return error?.body?.message ||
            error?.message ||
            this.currentLabel('errorMessage');
    }
}