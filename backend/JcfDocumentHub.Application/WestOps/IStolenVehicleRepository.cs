using JcfDocumentHub.Domain.WestOps;

namespace JcfDocumentHub.Application.WestOps;

public interface IStolenVehicleRepository
{
    Task<IReadOnlyList<StolenVehicle>> ListAsync(CancellationToken cancellationToken);

    Task<StolenVehicle?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<long> CountAsync(CancellationToken cancellationToken);

    Task InsertManyAsync(IEnumerable<StolenVehicle> vehicles, CancellationToken cancellationToken);
}
