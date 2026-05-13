using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.WestOps;
using JcfDocumentHub.Infrastructure.Persistence;
using MongoDB.Driver;

namespace JcfDocumentHub.Infrastructure.WestOps;

public sealed class MongoWantedPersonRepository : IWantedPersonRepository
{
    private readonly MongoContext context;

    public MongoWantedPersonRepository(MongoContext context)
    {
        this.context = context;
    }

    public async Task<IReadOnlyList<WantedPerson>> ListAsync(CancellationToken cancellationToken)
    {
        return await this.context.WantedPersons
            .Find(FilterDefinition<WantedPerson>.Empty)
            .SortBy(person => person.LastName)
            .ToListAsync(cancellationToken);
    }

    public async Task<WantedPerson?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await this.context.WantedPersons
            .Find(person => person.Id == id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public Task<long> CountAsync(CancellationToken cancellationToken)
    {
        return this.context.WantedPersons.CountDocumentsAsync(FilterDefinition<WantedPerson>.Empty, cancellationToken: cancellationToken);
    }

    public Task InsertManyAsync(IEnumerable<WantedPerson> persons, CancellationToken cancellationToken)
    {
        return this.context.WantedPersons.InsertManyAsync(persons, cancellationToken: cancellationToken);
    }
}
