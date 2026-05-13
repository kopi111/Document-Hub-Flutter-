# JCF Document Hub API (backend)

ASP.NET Core 8 backend for the JCF Document Hub. Exposes the REST surface defined
in proposal v2.0 §6, plus a News feed for Force-wide announcements and the WestOps
operational endpoints (wanted persons, missing persons, stolen vehicles, traffic
codes) ported from the legacy PHP/MySQL prototype at `~/projects/WestOPs/`.

This slice ships the **contract and skeleton** only. Most handlers return live
data from MongoDB once seeded; PDF byte-range streaming and thumbnail generation
return 501 Not Implemented and are tracked in `docs/IMPLEMENTATION_TODO.md`.

## Architecture

Clean Architecture layered layout (Domain / Application / Infrastructure / Presentation).
The Domain project has no dependencies. The Application project owns repository
interfaces and DTOs. The Infrastructure project implements the repositories on
top of `MongoDB.Driver`. The Api project hosts controllers, Swagger, and the JWT
authentication scheme. Namespaces are prefixed `JcfDocumentHub.*`.

```
backend/
  JcfDocumentHub.sln
  JcfDocumentHub.Domain/          entities, value objects
  JcfDocumentHub.Application/     interfaces, DTOs, validators
  JcfDocumentHub.Infrastructure/  MongoContext, repositories, seeder
  JcfDocumentHub.Api/             controllers, Program.cs, Swagger
  JcfDocumentHub.Api.Tests/       integration tests (xUnit)
```

## Run

```
cd backend
dotnet run --project JcfDocumentHub.Api
```

The API listens on `http://localhost:5080` by default. Swagger UI is at
`http://localhost:5080/swagger`. The unauthenticated health probe is at
`http://localhost:5080/health`.

## Seed

```
cd backend
dotnet run --project JcfDocumentHub.Api -- seed
```

Seeding is **lazy**: the seeder skips any collection that already contains rows.
It loads three sample news articles, the three wanted persons / one missing
person / three stolen vehicles from `WestOPs/sql/westapp.sql`, and four sample
traffic-code entries.

## Configuration

MongoDB connection lives in `appsettings.json` (production defaults) and
`appsettings.Development.json` (developer overrides). Both point at
`mongodb://localhost:27017/jcf_document_hub` out of the box.

JWT validation is currently a **development scaffold** — any well-formed bearer
token is accepted and its `email` claim is copied to `HttpContext.User`. Before
pilot deployment, wire the bearer scheme to the JCF Microsoft 365 JWKS endpoint
(see `Authentication/DevelopmentJwtBearer.cs` and the comment at the top of
`Program.cs`).

## Test

```
cd backend
dotnet test
```

There is one integration test that boots the API and asserts `/health` returns
200. Stub handlers are not under test until they ship real logic.
