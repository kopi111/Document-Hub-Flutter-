using JcfDocumentHub.Domain.WestOps;

namespace JcfDocumentHub.Application.WestOps;

public interface IWantedPersonRepository
{
    Task<IReadOnlyList<WantedPerson>> ListAsync(CancellationToken cancellationToken);

    Task<WantedPerson?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<long> CountAsync(CancellationToken cancellationToken);

    Task InsertManyAsync(IEnumerable<WantedPerson> persons, CancellationToken cancellationToken);
}
