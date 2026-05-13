using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.WestOps;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/westops/traffic-codes")]
public sealed class TrafficCodesController : ControllerBase
{
    private readonly ITrafficCodeRepository codes;

    public TrafficCodesController(ITrafficCodeRepository codes)
    {
        this.codes = codes;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<TrafficCode>>> List(CancellationToken cancellationToken)
    {
        IReadOnlyList<TrafficCode> result = await this.codes.ListAsync(cancellationToken);
        return this.Ok(result);
    }
}
