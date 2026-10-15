# Communities & Sites

Standard Salesforce-generated Experience Cloud / Sites controllers. The VF pages are not in this source folder (page references in code: `ForgotPasswordConfirm`, `CommunitiesSelfRegConfirm`, `SiteRegisterConfirm`, `ChangePassword`). All tests use `@IsTest(SeeAllData=true)`.

| Class | Sharing | Entry points | Platform API | Notes | Test |
|---|---|---|---|---|---|
| ChangePasswordController | with | `changePassword()`; props `oldPassword`, `newPassword`, `verifyNewPassword` | `Site.changePassword` | – | ChangePasswordControllerTest |
| CommunitiesLandingController | with | `forwardToStartPage()` | `Network.communitiesLanding()` | – | CommunitiesLandingControllerTest |
| CommunitiesLoginController | with (global) | `forwardToAuthPage()` | `Network.forwardToAuthPage(startURL, display)` | URL params `startURL`, `display` | CommunitiesLoginControllerTest |
| CommunitiesSelfRegConfirmController | with | constructor only | – | Empty | CommunitiesSelfRegConfirmControllerTest |
| CommunitiesSelfRegController | **none declared** | `registerUser()`; props first/last name, email, password, confirmPassword, communityNickname | `Site.setExperienceId`, `Site.createExternalUser`, `Site.login` | `profileId = null`, `accountId = ''` ("To be filled in by customer") – template never configured | CommunitiesSelfRegControllerTest |
| ForgotPasswordController | with | `forgotPassword()` | `Site.forgotPassword` | Redirects to `ForgotPasswordConfirm` | ForgotPasswordControllerTest |
| MicrobatchSelfRegController | **none declared** | `registerUser()` | `Network.createExternalUserAsync(u, contact, account)` | Creates Account "Account for {lastName}" + Contact; `profileId = null`; locale en_US/GMT | MicrobatchSelfRegControllerTest |
| MyProfilePageController | with | `getUser()`, `getIsEdit()`, `edit()`, `save()`, `changePassword()`, `cancel()`, `static setContactFields(Contact, User)` | – | Throws `NoAccessException` for GUEST; save updates User and copies title/name/email/phone/mobile/fax/mailing address to `User.Contact` | MyProfilePageControllerTest |
| SiteLoginController | with (global) | `login()` | `Site.login` | – | SiteLoginControllerTest |
| SiteRegisterController | with | `registerUser()` | `Site.createPortalUser` | **Hardcoded placeholder `PORTAL_ACCOUNT_ID = '001x000xxx35tPN'` (L7)** – not a valid Id | SiteRegisterControllerTest |

**Objects/fields:** only standard (User, Contact, Account). No custom fields.

**Risks**
- Self-registration controllers are unconfigured templates (null profile / placeholder account); if exposed on a live site they will fail or create users with no profile.
- `SiteRegisterController.PORTAL_ACCOUNT_ID` is a hardcoded, invalid Id.
- `CommunitiesSelfRegController` / `MicrobatchSelfRegController` run without a sharing declaration on a guest-facing page.
