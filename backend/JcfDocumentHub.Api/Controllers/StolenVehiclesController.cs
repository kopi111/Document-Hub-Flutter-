using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.WestOps;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/westops/stolen-vehicles")]
public sealed class StolenVehiclesController : ControllerBase
{
    private readonly IStolenVehicleRepository stolen;

    public StolenVehiclesController(IStolenVehicleRepository stolen)
    {
        this.stolen = stolen;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<StolenVehicle>>> List(CancellationToken cancellationToken)
    {
        IReadOnlyList<StolenVehicle> vehicles = await this.stolen.ListAsync(cancellationToken);
        return this.Ok(vehicles);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<StolenVehicle>> Get(string id, CancellationToken cancellationToken)
    {
        StolenVehicle? vehicle = await this.stolen.FindByIdAsync(id, cancellationToken);
        if (vehicle is null)
        {
            return this.NotFound();
        }
        return this.Ok(vehicle);
    }
}
