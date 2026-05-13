using JcfDocumentHub.Domain.Common;
using JcfDocumentHub.Domain.Documents;

namespace JcfDocumentHub.Application.Documents;

public interface IDocumentRepository
{
    Task<PagedResult<PolicyDocument>> ListByCategoryAsync(
        string categoryId,
        int page,
        int pageSize,
        string sort,
        string order,
        CancellationToken cancellationToken);

    Task<PagedResult<PolicyDocument>> SearchAsync(
        string term,
        int page,
        int pageSize,
        CancellationToken cancellationToken);

    Task<PolicyDocument?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<IReadOnlyList<PolicyDocument>> ListAllAsync(CancellationToken cancellationToken);

    Task<long> CountAsync(CancellationToken cancellationToken);
}
