using JcfDocumentHub.Domain.Audit;
using JcfDocumentHub.Domain.Documents;
using JcfDocumentHub.Domain.News;
using JcfDocumentHub.Domain.WestOps;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace JcfDocumentHub.Infrastructure.Persistence;

public sealed class MongoContext
{
    private readonly IMongoDatabase database;

    public MongoContext(IOptions<MongoSettings> settings)
    {
        ArgumentNullException.ThrowIfNull(settings);
        MongoSettings value = settings.Value;
        if (string.IsNullOrWhiteSpace(value.ConnectionString))
        {
            throw new InvalidOperationException("MongoDB connection string is not configured.");
        }
        if (string.IsNullOrWhiteSpace(value.DatabaseName))
        {
            throw new InvalidOperationException("MongoDB database name is not configured.");
        }
        MongoClient client = new(value.ConnectionString);
        this.database = client.GetDatabase(value.DatabaseName);
    }

    public IMongoCollection<Category> Categories => this.database.GetCollection<Category>("categories");

    public IMongoCollection<PolicyDocument> Documents => this.database.GetCollection<PolicyDocument>("documents");

    public IMongoCollection<AuditEvent> AuditEvents => this.database.GetCollection<AuditEvent>("audit_events");

    public IMongoCollection<NewsArticle> News => this.database.GetCollection<NewsArticle>("news");

    public IMongoCollection<WantedPerson> WantedPersons => this.database.GetCollection<WantedPerson>("wanted_persons");

    public IMongoCollection<MissingPerson> MissingPersons => this.database.GetCollection<MissingPerson>("missing_persons");

    public IMongoCollection<StolenVehicle> StolenVehicles => this.database.GetCollection<StolenVehicle>("stolen_vehicles");

    public IMongoCollection<TrafficCode> TrafficCodes => this.database.GetCollection<TrafficCode>("traffic_codes");
}
