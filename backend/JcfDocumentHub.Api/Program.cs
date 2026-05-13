// =============================================================================
// JCF Document Hub API — composition root
//
// WARNING (unsafe scaffold): JWT validation is currently a DEVELOPMENT-ONLY
// stub (see Authentication/DevelopmentJwtBearer.cs). Any well-formed bearer
// token is accepted. Before any pilot deployment, replace the stub with full
// JCF Microsoft 365 JWKS validation (Authority + Audience from the JCF tenant)
// and remove this notice.
// =============================================================================

using JcfDocumentHub.Api.Authentication;
using JcfDocumentHub.Infrastructure;
using JcfDocumentHub.Infrastructure.Seeding;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.OpenApi.Models;

if (args.Length > 0 && string.Equals(args[0], "seed", StringComparison.OrdinalIgnoreCase))
{
    await SeedRunner.RunAsync(args);
    return;
}

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddScoped<DatabaseSeeder>();

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(DevelopmentJwtBearer.Configure);
builder.Services.AddAuthorization();

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "JCF Document Hub API",
        Version = "v1",
        Description = "REST surface for the JCF Document Hub (v2.0 proposal §6), News feed, and WestOps operational features."
    });
    OpenApiSecurityScheme bearerScheme = new()
    {
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Paste a bearer token here. Token validation is currently a development stub."
    };
    options.AddSecurityDefinition("Bearer", bearerScheme);
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

WebApplication app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

await app.RunAsync();

public partial class Program;
