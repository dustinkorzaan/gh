---
applyTo: "api/**"
---

# API (`/api`): C# / .NET 10

- Validate Entra ID tokens on every protected endpoint (scopes/roles via
  policies), never in a client.
- Blob access: issue short-lived, least-privilege SAS URIs using the API's
  managed identity (user delegation SAS). Never stream file bytes through an
  endpoint.
- Azure SQL via EF Core: every model change has a migration; keep queries
  translatable to SQL and avoid N+1 queries.
- Async all the way: await, flow `CancellationToken`, no `.Result`/`.Wait()`.
- Config comes from configuration/Key Vault, never hard-coded; add new
  settings to `appsettings*.json`, infra and docs.
- Tests: xUnit test projects under `api/`, included in the solution so
  `dotnet test` finds them. `dotnet test` must report at least one test.
