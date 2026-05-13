using JcfDocumentHub.Domain.WestOps;

namespace JcfDocumentHub.Application.WestOps;

public interface ITrafficCodeRepository
{
    Task<IReadOnlyList<TrafficCode>> ListAsync(CancellationToken cancellationToken);

    Task<long> CountAsync(CancellationToken cancellationToken);

    Task InsertManyAsync(IEnumerable<TrafficCode> codes, CancellationToken cancellationToken);
}
