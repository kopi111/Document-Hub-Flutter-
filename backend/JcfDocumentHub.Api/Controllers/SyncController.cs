using JcfDocumentHub.Application.Documents;
using JcfDocumentHub.Domain.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/sync")]
public sealed class SyncController : ControllerBase
{
    private readonly IDocumentRepository documents;

    public SyncController(IDocumentRepository documents)
    {
        this.documents = documents;
    }

    [HttpGet("manifest")]
    public async Task<ActionResult<IReadOnlyList<SyncManifestEntry>>> Manifest(CancellationToken cancellationToken)
    {
        IReadOnlyList<PolicyDocument> all = await this.documents.ListAllAsync(cancellationToken);
        List<SyncManifestEntry> manifest = all
            .Select(document => new SyncManifestEntry(
                document.Id,
                document.Title,
                document.CategoryId,
                document.Sha256Hash,
                document.VersionNumber,
                document.LastModifiedUtc,
                document.FileSizeBytes))
            .ToList();
        return this.Ok(manifest);
    }
}
