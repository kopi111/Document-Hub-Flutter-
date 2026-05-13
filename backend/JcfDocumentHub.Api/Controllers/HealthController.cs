using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[AllowAnonymous]
[Route("health")]
public sealed class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return this.Ok(new { status = "ok", service = "JCF Document Hub API", timestampUtc = DateTime.UtcNow });
    }
}
