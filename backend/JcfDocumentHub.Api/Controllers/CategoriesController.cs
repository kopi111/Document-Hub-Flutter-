using JcfDocumentHub.Application.Common;
using JcfDocumentHub.Application.Documents;
using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/categories")]
public sealed class CategoriesController : ControllerBase
{
    private readonly ICategoryRepository categories;
    private readonly IDocumentRepository documents;

    public CategoriesController(ICategoryRepository categories, IDocumentRepository documents)
    {
        this.categories = categories;
        this.documents = documents;
    }

    // TODO (proposal §5.3): filter the returned categories by the caller's AD groups.
    // Until JCF tenant access is provisioned, every authenticated caller sees every category.
    [HttpGet]
    public async Task<ActionResult<PagedResult<Category>>> List(
        [FromQuery] int? page,
        [FromQuery(Name = "page_size")] int? pageSize,
        CancellationToken cancellationToken)
    {
        PageRequest request = PageRequest.Normalise(page, pageSize);
        PagedResult<Category> result = await this.categories.ListAsync(request.Page, request.PageSize, cancellationToken);
        return this.Ok(result);
    }

    [HttpGet("{id}/documents")]
    public async Task<ActionResult<PagedResult<PolicyDocument>>> ListDocuments(
        string id,
        [FromQuery] int? page,
        [FromQuery(Name = "page_size")] int? pageSize,
        [FromQuery] string sort = "name",
        [FromQuery] string order = "asc",
        CancellationToken cancellationToken = default)
    {
        PageRequest request = PageRequest.Normalise(page, pageSize);
        PagedResult<PolicyDocument> result = await this.documents.ListByCategoryAsync(id, request.Page, request.PageSize, sort, order, cancellationToken);
        return this.Ok(result);
    }
}
