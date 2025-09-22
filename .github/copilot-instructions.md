## Angular Folder Structure Best Practices

- Use the Angular CLI to generate modules, components, and services.
- Organize code by feature modules (e.g., `/src/app/features/go-url/`).
- Place shared components, directives, and pipes in a `/shared/` folder.
- Store core services and singleton providers in a `/core/` folder.
- Keep assets (images, styles, etc.) in the `/assets/` folder.
- Use clear, descriptive names for files and folders (e.g., `go-url-list`, `go-url-detail`).
- Avoid deep nesting; keep folder hierarchy simple and maintainable.
- Group unit tests with their respective components (e.g., `component-name.component.spec.ts`).
- Maintain a consistent naming convention for files and folders (kebab-case recommended).


# Copilot Instructions & Coding Standards

This project uses the following tech stack:
- **Backend:** .NET Core (C#)
- **Database:** PostgreSQL
- **Frontend:** Angular
- **Authentication:** Windows Authentication (Active Directory)
- **Unit Testing:** Jasmine/Karma (Angular)
- **E2E Testing:** Playwright

## Folder Structure
my-angular-project/
├── node_modules/
├── src/
│   ├── app/
│   │   ├── core/
│   │   ├── shared/
│   │   ├── features/
│   │   │   └── user-management/
│   │   │       ├── components/
│   │   │       └── services/
│   │   ├── layout/
│   │   └── app.component.ts
│   ├── assets/
│   ├── environments/
│   └── styles/
file
├── angular.json
├── package.json
└── tsconfig.json

## Copilot Best Practices
- Use Copilot for boilerplate, repetitive code, and scaffolding.
- Always review, refactor, and test Copilot-generated code before merging.
- For business logic, security, and authentication, manually validate all code.
- Use descriptive comments to guide Copilot for more relevant suggestions.

## Coding Standards

### .NET Core (C#)
- Follow Microsoft C# coding conventions (PascalCase for types/methods, camelCase for variables).
- Use dependency injection and separation of concerns.
- Write XML documentation for public APIs.
- Validate all user input and handle exceptions gracefully.

### SQL Server
- Use parameterized queries to prevent SQL injection.
- Normalize database schema and use appropriate indexing.
- Store connection strings securely (environment variables or secrets manager).

### Angular
- Use Angular CLI for project scaffolding and code generation.
- Follow Angular style guide (file naming, folder structure, component organization).
- Use TypeScript strict mode and interfaces for type safety.
- Prefer reactive forms and observables for data handling.

### Testing
- Write unit tests for all components/services using Jasmine/Karma.
- Use Playwright for end-to-end testing of user flows and authentication.
- Maintain high test coverage and run tests on every commit.

## How to Use Copilot
1. Start typing code or comments to trigger Copilot suggestions.
2. Accept, reject, or modify suggestions as needed.
3. Use Copilot chat for explanations, code generation, and troubleshooting.

## Troubleshooting
- If suggestions are not relevant, provide more context or comments.
- For errors, check code for syntax, logic, and security issues before accepting.

## Resources
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [Microsoft C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/inside-a-program/coding-conventions)
- [Angular Style Guide](https://angular.io/guide/styleguide)
- [Playwright Documentation](https://playwright.dev/)

---
Use this file to help all team members follow best practices and maintain high code quality with Copilot.