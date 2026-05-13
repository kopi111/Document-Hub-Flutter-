using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.WestOps;
using JcfDocumentHub.Infrastructure.Persistence;
using MongoDB.Driver;

namespace JcfDocumentHub.Infrastructure.WestOps;

public sealed class MongoStolenVehicleRepository : IStolenVehicleRepository
{
    private readonly MongoContext context;

    public MongoStolenVehicleRepository(MongoContext context)
    {
        this.context = context;
    }

    public async Task<IReadOnlyList<StolenVehicle>> ListAsync(CancellationToken cancellationToken)
    {
        return await this.context.StolenVehicles
            .Find(FilterDefinition<StolenVehicle>.Empty)
            .SortByDescending(vehicle => vehicle.DateStolen)
            .ToListAsync(cancellationToken);
    }

    public async Task<StolenVehicle?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await this.context.StolenVehicles
            .Find(vehicle => vehicle.Id == id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public Task<long> CountAsync(CancellationToken cancellationToken)
    {
        return this.context.StolenVehicles.CountDocumentsAsync(FilterDefinition<StolenVehicle>.Empty, cancellationToken: cancellationToken);
    }

    public Task InsertManyAsync(IEnumerable<StolenVehicle> vehicles, CancellationToken cancellationToken)
    {
        return this.context.StolenVehicles.InsertManyAsync(vehicles, cancellationToken: cancellationToken);
    }
}
