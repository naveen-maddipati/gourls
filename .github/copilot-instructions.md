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
- **Backend:** .NET Core (C#) with Entity Framework Core
- **Database:** PostgreSQL with Docker containerization
- **Frontend:** Angular (Standalone Components, Angular 20+)
- **UI Framework:** Bootstrap 5 (global styles), Bootstrap Icons
- **Routing:** Go Links (dynamic route matching for short URLs)
- **State Management:** Angular Signals (where applicable)
- **Authentication:** Windows Authentication (Active Directory) - *Currently disabled*
- **Unit Testing:** Jasmine/Karma (Angular)
- **E2E Testing:** Playwright
- **Reverse Proxy:** nginx for URL masking and routing
- **Development Environment:** Docker PostgreSQL, nginx proxy setup
- **Package Management:** npm (Angular), NuGet (.NET)
- **Build Tools:** Angular CLI, .NET CLI

## Additional Technologies & Patterns
- **Bootstrap 5** for responsive UI and modals/alerts
- **Bootstrap Icons** for consistent iconography
- **Angular Standalone Components** for modular architecture
- **Go Links Routing** for short URL redirection
- **Signal API** for reactive state (where used)
- **Custom Notification & Modal Patterns** for consistent UX
- **nginx Reverse Proxy** for clean URL routing (go/ domain)
- **Entity Framework Core** for database ORM and migrations
- **Docker PostgreSQL** for development database
- **MCP (Model Context Protocol)** for database interactions
- **RESTful API Design** with minimal API patterns
- **CORS Configuration** for cross-origin requests
- **Development Automation** with shell scripts for setup/deployment

## Folder Structure
GoUrls_Code/
├── GoUrlsApi/                          # .NET Core API
│   ├── Controllers/                    # API controllers
│   │   └── UrlsController.cs          # Main URLs CRUD operations
│   ├── Models/                        # Data models and DbContext
│   │   ├── UrlEntry.cs               # URL entity model
│   │   └── GoUrlsDbContext.cs        # EF Core context
│   ├── Migrations/                    # EF Core database migrations
│   └── Program.cs                     # API startup configuration
├── go-urls-app/                       # Angular application
│   ├── src/app/
│   │   ├── core/                      # Core services and constants
│   │   ├── shared/                    # Shared components
│   │   ├── features/
│   │   │   ├── home/                  # Home page component
│   │   │   └── url-management/        # URL management feature
│   │   │       ├── components/        # URL-related components
│   │   │       ├── services/          # URL management service
│   │   │       └── models/            # TypeScript interfaces
│   │   ├── layout/                    # Layout components
│   │   └── app.routes.ts             # Application routing
│   ├── assets/                       # Static assets
│   └── environments/                 # Environment configurations
├── nginx-go-proxy.conf               # nginx reverse proxy config
├── setup-dev.sh                     # Development setup script
├── start-dev.sh                     # Start development environment
├── stop-dev.sh                      # Stop development environment
└── Documentation/
    ├── DEV-SETUP.md                 # Development setup guide
    └── NGINX-SETUP-COMPLETE.md     # nginx configuration guide

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

### PostgreSQL & Database
- Use parameterized queries to prevent SQL injection.
- Normalize database schema and use appropriate indexing.
- Store connection strings securely (environment variables or secrets manager).
- Use Entity Framework Core migrations for schema changes.
- Leverage Docker containers for development database consistency.
- Follow PostgreSQL naming conventions (snake_case for tables/columns).

### Infrastructure & DevOps
- Use nginx for reverse proxy and URL masking in development.
- Configure CORS properly for cross-origin API requests.
- Implement proper error handling and logging.
- Use Docker for consistent development environments.
- Automate development setup with shell scripts.
- Document all infrastructure requirements and setup procedures.


### Angular & UI
- Use Angular CLI for project scaffolding and code generation.
- Prefer Standalone Components for new features.
- Use Angular Signals for reactive state where appropriate.
- Follow Angular style guide (file naming, folder structure, component organization).
- Use TypeScript strict mode and interfaces for type safety.
- Prefer reactive forms and observables for data handling.
- Use Bootstrap 5 for layout, modals, alerts, and forms.
- Use Bootstrap Icons for all icon needs.
- Implement notification and modal patterns globally for consistent UX.


### Testing
- Write unit tests for all components/services using Jasmine/Karma.
- Use Playwright for end-to-end testing of user flows and authentication.
- Maintain high test coverage and run tests on every commit.
- Test Go Links routing and notification/modal flows.

## How to Use Copilot
1. Start typing code or comments to trigger Copilot suggestions.
2. Accept, reject, or modify suggestions as needed.
3. Use Copilot chat for explanations, code generation, and troubleshooting.

## Development Workflow
### Getting Started
1. Run `./setup-dev.sh` for one-time environment setup
2. Use `./start-dev.sh` to start the development environment
3. Access the app at `http://go/` or `http://localhost:4200/`
4. Use `./stop-dev.sh` to stop all services

### Database Management
- PostgreSQL runs in Docker container on port 5431
- Use `dotnet ef migrations add <name>` for schema changes
- Apply migrations with `dotnet ef database update`
- Access database via MCP server for queries and debugging

### URL Testing
- Create short URLs in the application
- Test redirects via `http://go/shortname`
- Use browser dev tools to debug redirect issues
- Check nginx logs for proxy-related problems

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