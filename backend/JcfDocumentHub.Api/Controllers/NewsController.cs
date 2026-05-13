using JcfDocumentHub.Application.Common;
using JcfDocumentHub.Application.News;
using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.News;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/news")]
public sealed class NewsController : ControllerBase
{
    private readonly INewsRepository news;

    public NewsController(INewsRepository news)
    {
        this.news = news;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<NewsArticle>>> List(
        [FromQuery] int? page,
        [FromQuery(Name = "page_size")] int? pageSize,
        [FromQuery] string order = "desc",
        CancellationToken cancellationToken = default)
    {
        PageRequest request = PageRequest.Normalise(page, pageSize);
        PagedResult<NewsArticle> result = await this.news.ListAsync(request.Page, request.PageSize, order, cancellationToken);
        return this.Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<NewsArticle>> Get(string id, CancellationToken cancellationToken)
    {
        NewsArticle? article = await this.news.FindByIdAsync(id, cancellationToken);
        if (article is null)
        {
            return this.NotFound();
        }
        return this.Ok(article);
    }

    // TODO (proposal §5): scaffold admin authorisation. The intended check is
    // [Authorize(Policy = "NewsEditors")] backed by the JCF-DocHub-NewsEditors AD group.
    [HttpPost]
    public async Task<ActionResult<NewsArticle>> Create([FromBody] NewsArticle article, CancellationToken cancellationToken)
    {
        if (article is null || string.IsNullOrWhiteSpace(article.Title))
        {
            return this.BadRequest(new { error = "Title is required." });
        }
        if (article.PublishedAtUtc == default)
        {
            article.PublishedAtUtc = DateTime.UtcNow;
        }
        await this.news.InsertAsync(article, cancellationToken);
        return this.CreatedAtAction(nameof(Get), new { id = article.Id }, article);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] NewsArticle article, CancellationToken cancellationToken)
    {
        if (article is null)
        {
            return this.BadRequest();
        }
        NewsArticle? existing = await this.news.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return this.NotFound();
        }
        article.Id = id;
        await this.news.ReplaceAsync(article, cancellationToken);
        return this.NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken)
    {
        NewsArticle? existing = await this.news.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return this.NotFound();
        }
        await this.news.DeleteAsync(id, cancellationToken);
        return this.NoContent();
    }
}
