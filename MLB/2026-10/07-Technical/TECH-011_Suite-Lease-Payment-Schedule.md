# TECH-011 — Suite Lease payment schedule and Person Account Type values

| | |
|---|---|
| **ID** | TECH-011 |
| **Requirements** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) · [REQ-020](../03-Requirements/REQ-020_Person-Account-Type-Values.md) |
| **Source** | `flows/Agreement_Flow.flow-meta.xml` (v75), `objects/Opportunity/fields/…`, `objects/Opportunity/validationRules/…`, `flexipages/Ticketing_Opportunity_LRP…`, `layouts/Opportunity-Opportunity Layout…`, `objects/PersonAccount/recordTypes/PersonAccount…` |

## 1. Fields (Opportunity)
| API name | Label | Type | Notes |
|---|---|---|---|
| `Number_of_Payment_Plans__c` | Number of Payment Schedule | Picklist, restricted: Full, 2–12 | API name kept from the first build |
| `Payment_Amount__c` | Payment Amount | Text(18) | Numbers only (rule below) |
| `Payment_Due_Date_1__c` … `_12__c` | Payment N Due Date | Text(30) | "Month D, YYYY" (CON-019) |
| `Due_Date__c` (existing) | Due Date | Date | = payment 1 date |

Profiles Admin, Ticket Sales, Marlins Sales Leadership and Marlins IT Admin: read and edit. Edits are still blocked by the lock rule.

## 2. Validation rules
| Rule | Logic |
|---|---|
| `Payment_Amounts_Numeric_Only` | `AND(NOT(ISBLANK(Payment_Amount__c)), NOT(REGEX(Payment_Amount__c, "^[0-9]+(\\.[0-9]{1,2})?$")))` |
| `Agreement_Sections_Flow_Only` | Now 44 locked fields: Year 1–5 License Fee removed; Number_of_Payment_Plans__c, Payment_Amount__c and Payment_Due_Date_1–12__c added. Exception unchanged: `Agreement_Flow_Update__c` flipped in the same save (TECH-009). |

## 3. Agreement Flow (Suite Lease screen)
```
Suite_Number_of_Payment_Plans (dropdown, required, default frmExistingPaymentPlans)
  ├─ Full  → Suite_Full_Payment_Due_Date   "Due Date"           (required, default frmExistingDue1)
  └─ 2..12 → Suite_Payment_Due_Date_1..N   "Payment N Due Date" (required, default frmExistingDueN)
Assign_Suite_To_Opportunity
  Number_of_Payment_Plans__c = dropdown
  Payment_Amount__c          = frmPayAmount
  Payment_Due_Date_N__c      = frmPayDueNText   (blank when N > count)
  Due_Date__c                = frmPayDue1       (date)
```
| Formula | Expression (summary) |
|---|---|
| `frmPaymentCount` | Full → 1; otherwise VALUE(dropdown); blank → 0 |
| `frmPayAmountCents` / `frmPayAmount` | ROUND(total × 100 ÷ count, 0) → text with 2 decimals |
| `frmPayDueN` (Date) | the screen date when count ≥ N, else `nullDate`; `frmPayDue1` uses the Full field when Full |
| `frmPayDueNText` | `CASE(MONTH(d), 1, "January", …) & " " & TEXT(DAY(d)) & ", " & TEXT(YEAR(d))`, blank when no date |
| `frmExistingDueN` (Date) | Parses the saved text: `DATE(VALUE(RIGHT(t,4)), CASE(LEFT(t, FIND(" ",t)-1), "January",1, …), VALUE(MID(t, FIND(" ",t)+1, FIND(",",t)-FIND(" ",t)-1)))` |

- **Visibility** keys off the dropdown value, not a formula. Formulas are not re-evaluated on the screen (DEF-002). Payment 1 Due Date: not blank AND ≠ Full; dates 2–5: AND of "≠" the lower values; dates 6–12: OR of "=" N..12.
- A screen label can't change at run time, so Full has its own field, labelled "Due Date".
- `frmSuiteDueDate` (old today + 3 business days) is no longer used; kept to avoid touching unrelated elements.

## 4. Lightning page (`Ticketing_Opportunity_LRP`)
Section **Suite Payment Plan** (`flexipage_fieldSection_suitePayment`, facets `Facet-a19c0001-…-0001/0002/0003`), visible when `Agreement_Type__c` = Suite Lease. Row filters: see CON-020.

## 5. Adobe Document Builder
`adobesign__Document_Template__c` → `adobesign__Object_Field_Mapping__c` → `adobesign__Object_Field_Mapping_Entry__c` (`Document_Tag__c`, `Full_Api_Name__c`, `Index__c`). Entries and IDs: CR-039.

## 6. Person Account Type (REQ-020)
The record type `PersonAccount` lists the Account `Type` values it offers; Food and Beverage and Non-Profit were added. `Type` is not a restricted picklist, so the record type only controls what the screen offers. Check with UI API `/ui-api/object-info/Account/picklist-values/012Hu000002Dlx9IAC/Type`.

## 7. Production checklist
1. Deploy the fields (due dates as **Text(30)** directly), then the profiles, `Agreement_Flow`, the two validation rules, the page and the layout, and the PersonAccount record type.
2. Adobe: add the 15 entries to both Suite Lease document templates (CR-039) and place the tags in the Word files.
3. Test-generate one Suite Lease agreement without sending it.
