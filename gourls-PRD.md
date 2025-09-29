# Project Requirements Document: The go/urls Website

The following table outlines the detailed functional requirements of The go/urls website.

| Requirement ID | Description | User Story | Expected Behavior/Outcome |
|---------------|-------------|------------|--------------------------|
| FR001 | Creating a New URL & shortname entry | As a user, I want to be able to save an entry with full url and its shortname as a single record in the database | User can create a new shortname/URL entry, with uniqueness validated against the database. All managed URLs are shown in a table below the creation section. |
| FR002 | Editing URLs | As a user, I want to be able to edit the urls created by me | Grid supports inline editing with Bootstrap 5 UI components. |
| FR003 | Deleting URLs | As a user, I want to be able to delete the urls created by me | Grid supports inline delete with a stylish Bootstrap modal confirmation. Soft delete is performed in the database for auditing. |
| FR004 | Browsing url behaviour | As a user, I want to be able get redirected to the actual url if the user browse for go/shortname of the url | The system uses Go Links routing to dynamically redirect users to the associated long URL when browsing go/shortname. |
| FR005 | Searching for shortname availability | As a user, I want to be able to search for shortname availability | The system provides a grid of entries, with search working as a case-insensitive partial match. Banner notifications show shortname availability. Bootstrap Icons are used for info and actions. |
| FR006 | Unit testing | Unit tests coverage must be >95% | Jasmine/Karma unit tests for Angular, Playwright for E2E, and API code. |

## New Features & Technologies (2025)

- Angular 20+ Standalone Components for modular architecture
- Bootstrap 5 for responsive UI, modals, alerts, and forms
- Bootstrap Icons for consistent iconography
- Go Links Routing for dynamic short URL redirection
- Angular Signals for reactive state management
- Global notification and modal patterns for consistent UX
- DB uniqueness validation for shortnames
- Stylish Bootstrap modal for delete confirmation
- Improved banner and alert messaging below navbar
- All features tested with high coverage (unit & E2E)
