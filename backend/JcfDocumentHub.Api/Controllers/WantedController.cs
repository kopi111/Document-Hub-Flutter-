using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.WestOps;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/westops/wanted")]
public sealed class WantedController : ControllerBase
{
    private readonly IWantedPersonRepository wanted;

    public WantedController(IWantedPersonRepository wanted)
    {
        this.wanted = wanted;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<WantedPerson>>> List(CancellationToken cancellationToken)
    {
        IReadOnlyList<WantedPerson> persons = await this.wanted.ListAsync(cancellationToken);
        return this.Ok(persons);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<WantedPerson>> Get(string id, CancellationToken cancellationToken)
    {
        WantedPerson? person = await this.wanted.FindByIdAsync(id, cancellationToken);
        if (person is null)
        {
            return this.NotFound();
        }
        return this.Ok(person);
    }
}
