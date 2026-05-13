using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace JcfDocumentHub.Api.Authentication;

/// <summary>
///   TODO (PRE-PILOT): Replace this development scaffold with full JCF Microsoft 365
///   JWKS validation. The current implementation accepts any well-formed JWT and copies
///   the <c>email</c> or <c>upn</c> claim into <see cref="HttpContext.User"/>. It MUST
///   be wired to the JCF M365 tenant's signing keys (Authority + Audience) before any
///   real document content is served. See proposal section 4 for the production design.
/// </summary>
public static class DevelopmentJwtBearer
{
    public const string SchemeName = JwtBearerDefaults.AuthenticationScheme;

    public static void Configure(JwtBearerOptions options)
    {
        options.RequireHttpsMetadata = false;
        options.SaveToken = true;
        options.IncludeErrorDetails = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = false,
            ValidateIssuerSigningKey = false,
            SignatureValidator = (token, _) => new Microsoft.IdentityModel.JsonWebTokens.JsonWebToken(token),
            NameClaimType = "email",
            RoleClaimType = "roles"
        };
    }
}
