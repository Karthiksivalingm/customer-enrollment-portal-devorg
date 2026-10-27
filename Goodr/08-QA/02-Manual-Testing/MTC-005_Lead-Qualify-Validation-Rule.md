# MTC-005 — Lead validation rule: Sales Channel and Sector required to qualify

| | |
|---|---|
| **Document** | MTC-005 |
| **Requirement** | REQ-039 |
| **Automated test report** | [ATR-004](../01-Automated-Testing/ATR-004_Lead-Qualify-Validation-Rule.md): 15 of 15 scenarios passed on 2026-10-27 |
| **Environment** | Sandbox (GDRSAND), GOODR app |
| **How to use** | Run each test case in order. The **Expected result** is the outcome verified in the automated run. Write what you see in **Actual result** and mark **Status** as Pass or Fail. Add a screenshot of the error message (TC-039-01) and of the Qualified Lead (TC-039-03) to `MTC-005_screenshots/`. |

## What is being tested
A Lead cannot be set to **Qualified** while **Sales Channel** or **Sector** is blank. Because **Create Shopify** only works on Qualified Leads, a Shopify customer can no longer be created without both values.

## Before you start
- Create a test Lead named **QA Qualify Rule** with Status **New** and these fields: a 9-digit Tax ID, an Email, Terms of Service Agreement filled, Has Physical Store = Yes, Resale Certificate Status = "Yes, I do.", Parent Vertical filled. Leave **Sales Channel** and **Sector** blank.
- Delete the Lead at the end. Don't click **Create Shopify** on it unless you are testing TC-039-12, because that creates Accounts.

## Test case summary
| Test ID | Scenario | Expected result | Actual result | Status |
|---|---|---|---|---|
| TC-039-01 | Set Status to Qualified with Sector blank | Error on Status; Lead stays New | | |
| TC-039-02 | Both blank → Qualified | Same error | | |
| TC-039-03 | Both filled → Qualified | Saved as Qualified | | |
| TC-039-05 | Create a Lead with blanks | Saved | | |
| TC-039-06 | Edit another field with blanks | Saved | | |
| TC-039-07 | Set Status to Working with blanks | Saved | | |
| TC-039-09 | Approve button with blanks | Error; Lead stays New | | |
| TC-039-11 | Reject button with blanks | Manual Rejection | | |
| TC-039-12 | Create Shopify after qualifying | Button enabled only once Qualified | | |

---

## Test cases

### TC-039-01 — Sector blank → Qualified
| | |
|---|---|
| **Preconditions** | Lead **QA Qualify Rule**, Status New. Set Sales Channel to **Specialty**, leave Sector blank. |
| **Front-end steps** | 1. Open the Lead.<br>2. Click the pencil on **Status**, choose **Qualified**, click **Save**. |
| **Backend check** | Status is still New. |
| **Test data** | Sales Channel Specialty, Sector blank |
| **Expected result** | Error under Status: *"Please fill in Sales Channel and Sector before setting this Lead to Qualified."* |
| **Actual result** | |
| **Status** | Pass / Fail |

### TC-039-02 — Both blank → Qualified
| | |
|---|---|
| **Preconditions** | Clear Sales Channel (Sector clears with it). |
| **Front-end steps** | Repeat TC-039-01 steps. |
| **Backend check** | Status is still New. |
| **Test data** | Both blank |
| **Expected result** | The same error. |
| **Actual result** | |
| **Status** | Pass / Fail |

### TC-039-03 — Both filled → Qualified
| | |
|---|---|
| **Preconditions** | Set Sales Channel **Specialty** and Sector **Self Service**, Save. |
| **Front-end steps** | Set Status to **Qualified** and Save. |
| **Backend check** | Status is Qualified. |
| **Test data** | Specialty / Self Service |
| **Expected result** | Saved, no error. |
| **Actual result** | |
| **Status** | Pass / Fail |

### TC-039-05 — Create a Lead with blanks
| | |
|---|---|
| **Preconditions** | — |
| **Front-end steps** | Leads → New. Fill Last Name and Company only. Save. |
| **Backend check** | — |
| **Test data** | — |
| **Expected result** | Saved. Delete it afterwards. |
| **Actual result** | |
| **Status** | Pass / Fail |

### TC-039-06 — Edit another field with blanks
| | |
|---|---|
| **Preconditions** | A Lead with Sales Channel and Sector blank. |
| **Front-end steps** | Change **Company** and Save. |
| **Backend check** | — |
| **Test data** | — |
| **Expected result** | Saved. |
| **Actual result** | |
| **Status** | Pass / Fail |

### TC-039-07 — Other status with blanks
| | |
|---|---|
| **Preconditions** | A Lead with Sales Channel and Sector blank. |
| **Front-end steps** | Set Status to **Working** and Save. |
| **Backend check** | — |
| **Test data** | — |
| **Expected result** | Saved. |
| **Actual result** | |
| **Status** | Pass / Fail |

### TC-039-09 — Approve button with blanks
| | |
|---|---|
| **Preconditions** | A Lead with Status New and Sales Channel and Sector blank. |
| **Front-end steps** | Click **Approve**. |
| **Backend check** | Status is still New. |
| **Test data** | — |
| **Expected result** | An error message with the rule's text. |
| **Actual result** | |
| **Status** | Pass / Fail |

### TC-039-11 — Reject button with blanks
| | |
|---|---|
| **Preconditions** | A Lead with Sales Channel and Sector blank and an Email. |
| **Front-end steps** | Click **Reject**. |
| **Backend check** | Status is Manual Rejection. |
| **Test data** | — |
| **Expected result** | Rejected as before. **Note:** this sends the rejection email to the Lead's address; use a test address. |
| **Actual result** | |
| **Status** | Pass / Fail |

### TC-039-12 — Create Shopify after qualifying
| | |
|---|---|
| **Preconditions** | One Lead from TC-039-02 (blank, still New) and the Lead from TC-039-03 (Qualified). |
| **Front-end steps** | Open each Lead and click **Create Shopify**. Close the window without converting. |
| **Backend check** | — |
| **Test data** | — |
| **Expected result** | Blank Lead: the button is disabled ("Lead must be Qualified..."). Qualified Lead: the button is enabled. |
| **Actual result** | |
| **Status** | Pass / Fail |

---

## Sign-off
| | |
|---|---|
| **Tester name** | |
| **Test date** | |
| **Test cases passed** | ____ of 9 |
| **Overall result** | Pass / Fail |
| **Comments** | |
| **Signature** | |
