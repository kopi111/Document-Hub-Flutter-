using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.WestOps;
using JcfDocumentHub.Infrastructure.Persistence;
using MongoDB.Driver;

namespace JcfDocumentHub.Infrastructure.WestOps;

public sealed class MongoMissingPersonRepository : IMissingPersonRepository
{
    private readonly MongoContext context;

    public MongoMissingPersonRepository(MongoContext context)
    {
        this.context = context;
    }

    public async Task<IReadOnlyList<MissingPerson>> ListAsync(CancellationToken cancellationToken)
    {
        return await this.context.MissingPersons
            .Find(FilterDefinition<MissingPerson>.Empty)
            .SortByDescending(person => person.ReportedDate)
            .ToListAsync(cancellationToken);
    }

    public async Task<MissingPerson?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await this.context.MissingPersons
            .Find(person => person.Id == id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public Task<long> CountAsync(CancellationToken cancellationToken)
    {
        return this.context.MissingPersons.CountDocumentsAsync(FilterDefinition<MissingPerson>.Empty, cancellationToken: cancellationToken);
    }

    public Task InsertManyAsync(IEnumerable<MissingPerson> persons, CancellationToken cancellationToken)
    {
        return this.context.MissingPersons.InsertManyAsync(persons, cancellationToken: cancellationToken);
    }
}
