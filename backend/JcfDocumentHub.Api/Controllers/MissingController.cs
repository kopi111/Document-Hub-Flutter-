using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.WestOps;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/westops/missing")]
public sealed class MissingController : ControllerBase
{
    private readonly IMissingPersonRepository missing;

    public MissingController(IMissingPersonRepository missing)
    {
        this.missing = missing;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<MissingPerson>>> List(CancellationToken cancellationToken)
    {
        IReadOnlyList<MissingPerson> persons = await this.missing.ListAsync(cancellationToken);
        return this.Ok(persons);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<MissingPerson>> Get(string id, CancellationToken cancellationToken)
    {
        MissingPerson? person = await this.missing.FindByIdAsync(id, cancellationToken);
        if (person is null)
        {
            return this.NotFound();
        }
        return this.Ok(person);
    }
}
