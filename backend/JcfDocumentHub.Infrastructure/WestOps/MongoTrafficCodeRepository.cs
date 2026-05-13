using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.WestOps;
using JcfDocumentHub.Infrastructure.Persistence;
using MongoDB.Driver;

namespace JcfDocumentHub.Infrastructure.WestOps;

public sealed class MongoTrafficCodeRepository : ITrafficCodeRepository
{
    private readonly MongoContext context;

    public MongoTrafficCodeRepository(MongoContext context)
    {
        this.context = context;
    }

    public async Task<IReadOnlyList<TrafficCode>> ListAsync(CancellationToken cancellationToken)
    {
        return await this.context.TrafficCodes
            .Find(FilterDefinition<TrafficCode>.Empty)
            .SortBy(code => code.Code)
            .ToListAsync(cancellationToken);
    }

    public Task<long> CountAsync(CancellationToken cancellationToken)
    {
        return this.context.TrafficCodes.CountDocumentsAsync(FilterDefinition<TrafficCode>.Empty, cancellationToken: cancellationToken);
    }

    public Task InsertManyAsync(IEnumerable<TrafficCode> codes, CancellationToken cancellationToken)
    {
        return this.context.TrafficCodes.InsertManyAsync(codes, cancellationToken: cancellationToken);
    }
}
