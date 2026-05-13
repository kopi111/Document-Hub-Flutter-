using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.Documents;

namespace JcfDocumentHub.Application.Documents;

public interface ICategoryRepository
{
    Task<PagedResult<Category>> ListAsync(int page, int pageSize, CancellationToken cancellationToken);

    Task<Category?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<long> CountAsync(CancellationToken cancellationToken);
}
