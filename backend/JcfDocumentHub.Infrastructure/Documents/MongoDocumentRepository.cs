using JcfDocumentHub.Application.Documents;
using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.Documents;
using JcfDocumentHub.Infrastructure.Persistence;
using MongoDB.Driver;

namespace JcfDocumentHub.Infrastructure.Documents;

public sealed class MongoDocumentRepository : IDocumentRepository
{
    private readonly MongoContext context;

    public MongoDocumentRepository(MongoContext context)
    {
        this.context = context;
    }

    public async Task<PagedResult<PolicyDocument>> ListByCategoryAsync(
        string categoryId,
        int page,
        int pageSize,
        string sort,
        string order,
        CancellationToken cancellationToken)
    {
        FilterDefinition<PolicyDocument> filter = Builders<PolicyDocument>.Filter.Eq(document => document.CategoryId, categoryId);
        SortDefinition<PolicyDocument> sortDefinition = BuildSort(sort, order);
        long total = await this.context.Documents.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        if (total == 0)
        {
            return PagedResult<PolicyDocument>.Empty(page, pageSize);
        }
        List<PolicyDocument> items = await this.context.Documents
            .Find(filter)
            .Sort(sortDefinition)
            .Skip((page - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResult<PolicyDocument>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalItems = total
        };
    }

    public async Task<PagedResult<PolicyDocument>> SearchAsync(
        string term,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        FilterDefinition<PolicyDocument> filter = Builders<PolicyDocument>.Filter.Regex(
            document => document.Title,
            new MongoDB.Bson.BsonRegularExpression(System.Text.RegularExpressions.Regex.Escape(term), "i"));
        long total = await this.context.Documents.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        if (total == 0)
        {
            return PagedResult<PolicyDocument>.Empty(page, pageSize);
        }
        List<PolicyDocument> items = await this.context.Documents
            .Find(filter)
            .SortBy(document => document.Title)
            .Skip((page - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResult<PolicyDocument>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalItems = total
        };
    }

    public async Task<PolicyDocument?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await this.context.Documents
            .Find(document => document.Id == id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<PolicyDocument>> ListAllAsync(CancellationToken cancellationToken)
    {
        return await this.context.Documents.Find(FilterDefinition<PolicyDocument>.Empty).ToListAsync(cancellationToken);
    }

    public Task<long> CountAsync(CancellationToken cancellationToken)
    {
        return this.context.Documents.CountDocumentsAsync(FilterDefinition<PolicyDocument>.Empty, cancellationToken: cancellationToken);
    }

    private static SortDefinition<PolicyDocument> BuildSort(string sort, string order)
    {
        SortDefinitionBuilder<PolicyDocument> builder = Builders<PolicyDocument>.Sort;
        bool ascending = !string.Equals(order, "desc", StringComparison.OrdinalIgnoreCase);
        return sort.ToLowerInvariant() switch
        {
            "date" => ascending ? builder.Ascending(document => document.LastModifiedUtc) : builder.Descending(document => document.LastModifiedUtc),
            _ => ascending ? builder.Ascending(document => document.Title) : builder.Descending(document => document.Title)
        };
    }
}
