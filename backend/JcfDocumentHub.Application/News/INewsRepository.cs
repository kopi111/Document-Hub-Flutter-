using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.News;

namespace JcfDocumentHub.Application.News;

public interface INewsRepository
{
    Task<PagedResult<NewsArticle>> ListAsync(
        int page,
        int pageSize,
        string order,
        CancellationToken cancellationToken);

    Task<NewsArticle?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task InsertAsync(NewsArticle article, CancellationToken cancellationToken);

    Task ReplaceAsync(NewsArticle article, CancellationToken cancellationToken);

    Task DeleteAsync(string id, CancellationToken cancellationToken);

    Task<long> CountAsync(CancellationToken cancellationToken);
}
