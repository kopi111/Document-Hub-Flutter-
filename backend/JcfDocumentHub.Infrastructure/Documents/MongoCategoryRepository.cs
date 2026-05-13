using JcfDocumentHub.Application.Documents;
using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.Documents;
using JcfDocumentHub.Infrastructure.Persistence;
using MongoDB.Driver;

namespace JcfDocumentHub.Infrastructure.Documents;

public sealed class MongoCategoryRepository : ICategoryRepository
{
    private readonly MongoContext context;

    public MongoCategoryRepository(MongoContext context)
    {
        this.context = context;
    }

    public async Task<PagedResult<Category>> ListAsync(int page, int pageSize, CancellationToken cancellationToken)
    {
        long total = await this.context.Categories.CountDocumentsAsync(FilterDefinition<Category>.Empty, cancellationToken: cancellationToken);
        if (total == 0)
        {
            return PagedResult<Category>.Empty(page, pageSize);
        }
        List<Category> items = await this.context.Categories
            .Find(FilterDefinition<Category>.Empty)
            .SortBy(category => category.Name)
            .Skip((page - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResult<Category>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalItems = total
        };
    }

    public async Task<Category?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await this.context.Categories
            .Find(category => category.Id == id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public Task<long> CountAsync(CancellationToken cancellationToken)
    {
        return this.context.Categories.CountDocumentsAsync(FilterDefinition<Category>.Empty, cancellationToken: cancellationToken);
    }
}
