using JcfDocumentHub.Application.News;
using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.News;
using JcfDocumentHub.Infrastructure.Persistence;
using MongoDB.Driver;

namespace JcfDocumentHub.Infrastructure.News;

public sealed class MongoNewsRepository : INewsRepository
{
    private readonly MongoContext context;

    public MongoNewsRepository(MongoContext context)
    {
        this.context = context;
    }

    public async Task<PagedResult<NewsArticle>> ListAsync(
        int page,
        int pageSize,
        string order,
        CancellationToken cancellationToken)
    {
        long total = await this.context.News.CountDocumentsAsync(FilterDefinition<NewsArticle>.Empty, cancellationToken: cancellationToken);
        if (total == 0)
        {
            return PagedResult<NewsArticle>.Empty(page, pageSize);
        }
        bool descending = !string.Equals(order, "asc", StringComparison.OrdinalIgnoreCase);
        SortDefinition<NewsArticle> sort = descending
            ? Builders<NewsArticle>.Sort.Descending(article => article.PublishedAtUtc)
            : Builders<NewsArticle>.Sort.Ascending(article => article.PublishedAtUtc);
        List<NewsArticle> items = await this.context.News
            .Find(FilterDefinition<NewsArticle>.Empty)
            .Sort(sort)
            .Skip((page - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResult<NewsArticle>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalItems = total
        };
    }

    public async Task<NewsArticle?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await this.context.News
            .Find(article => article.Id == id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public Task InsertAsync(NewsArticle article, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(article);
        if (string.IsNullOrWhiteSpace(article.Id))
        {
            article.Id = Guid.NewGuid().ToString("N");
        }
        return this.context.News.InsertOneAsync(article, cancellationToken: cancellationToken);
    }

    public Task ReplaceAsync(NewsArticle article, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(article);
        FilterDefinition<NewsArticle> filter = Builders<NewsArticle>.Filter.Eq(existing => existing.Id, article.Id);
        return this.context.News.ReplaceOneAsync(filter, article, cancellationToken: cancellationToken);
    }

    public Task DeleteAsync(string id, CancellationToken cancellationToken)
    {
        return this.context.News.DeleteOneAsync(article => article.Id == id, cancellationToken);
    }

    public Task<long> CountAsync(CancellationToken cancellationToken)
    {
        return this.context.News.CountDocumentsAsync(FilterDefinition<NewsArticle>.Empty, cancellationToken: cancellationToken);
    }
}
