using JcfDocumentHub.Application.Common;
using JcfDocumentHub.Application.Documents;
using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/documents")]
public sealed class DocumentsController : ControllerBase
{
    private readonly IDocumentRepository documents;

    public DocumentsController(IDocumentRepository documents)
    {
        this.documents = documents;
    }

    [HttpGet("search")]
    public async Task<ActionResult<PagedResult<PolicyDocument>>> Search(
        [FromQuery] string q,
        [FromQuery] int? page,
        [FromQuery(Name = "page_size")] int? pageSize,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(q))
        {
            return this.BadRequest(new { error = "Query parameter 'q' is required." });
        }
        PageRequest request = PageRequest.Normalise(page, pageSize);
        PagedResult<PolicyDocument> result = await this.documents.SearchAsync(q, request.Page, request.PageSize, cancellationToken);
        return this.Ok(result);
    }

    [HttpGet("{id}/metadata")]
    public async Task<ActionResult<PolicyDocument>> Metadata(string id, CancellationToken cancellationToken)
    {
        PolicyDocument? document = await this.documents.FindByIdAsync(id, cancellationToken);
        if (document is null)
        {
            return this.NotFound();
        }
        return this.Ok(document);
    }

    // TODO (proposal §6.3): implement HTTP Range header byte streaming from the document store.
    // Until the storage backend is wired up, every content request returns 501 Not Implemented.
    [HttpGet("{id}/content")]
    public IActionResult StreamContent(string id)
    {
        _ = this.Request.Headers.Range;
        return this.StatusCode(StatusCodes.Status501NotImplemented, new
        {
            documentId = id,
            message = "Document streaming is not yet implemented."
        });
    }

    // TODO (proposal §6.3): serve cached JPEG thumbnail (max 256x256, 24 h cache).
    [HttpGet("{id}/thumbnail")]
    public IActionResult Thumbnail(string id)
    {
        return this.StatusCode(StatusCodes.Status501NotImplemented, new
        {
            documentId = id,
            message = "Thumbnail generation is not yet implemented."
        });
    }
}
