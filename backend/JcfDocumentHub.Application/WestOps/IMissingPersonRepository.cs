using JcfDocumentHub.Domain.WestOps;

namespace JcfDocumentHub.Application.WestOps;

public interface IMissingPersonRepository
{
    Task<IReadOnlyList<MissingPerson>> ListAsync(CancellationToken cancellationToken);

    Task<MissingPerson?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<long> CountAsync(CancellationToken cancellationToken);

    Task InsertManyAsync(IEnumerable<MissingPerson> persons, CancellationToken cancellationToken);
}
