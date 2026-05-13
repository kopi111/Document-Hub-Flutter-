using JcfDocumentHub.Domain.Audit;
using JcfDocumentHub.Domain.Documents;
using JcfDocumentHub.Domain.News;
using JcfDocumentHub.Domain.WestOps;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Bson.Serialization.Serializers;

namespace JcfDocumentHub.Infrastructure.Persistence;

/// <summary>
///   Registers BSON class maps once per process. Domain entities use string identifiers
///   (Mongo ObjectId hex strings or seeded GUIDs); enums are serialised as strings so
///   audit logs and news priorities remain human-readable in the collection.
/// </summary>
public static class MongoClassMapRegistry
{
    private static int registered;

    public static void Register()
    {
        if (Interlocked.Exchange(ref registered, 1) == 1)
        {
            return;
        }

        ConventionPack pack = new()
        {
            new CamelCaseElementNameConvention(),
            new IgnoreExtraElementsConvention(true),
            new EnumRepresentationConvention(BsonType.String)
        };
        ConventionRegistry.Register("JcfDocumentHub", pack, type => type.Namespace?.StartsWith("JcfDocumentHub.Domain", StringComparison.Ordinal) == true);

        RegisterEntity<Category>();
        RegisterEntity<PolicyDocument>();
        RegisterEntity<AuditEvent>();
        RegisterEntity<NewsArticle>();
        RegisterEntity<WantedPerson>();
        RegisterEntity<MissingPerson>();
        RegisterEntity<StolenVehicle>();
        RegisterEntity<TrafficCode>();
    }

    private static void RegisterEntity<T>() where T : class
    {
        if (BsonClassMap.IsClassMapRegistered(typeof(T)))
        {
            return;
        }
        BsonClassMap.RegisterClassMap<T>(map =>
        {
            map.AutoMap();
            BsonMemberMap? idMember = map.GetMemberMap("Id");
            if (idMember is not null)
            {
                idMember.SetElementName("_id");
                idMember.SetSerializer(new StringSerializer(BsonType.String));
                map.SetIdMember(idMember);
            }
        });
    }
}
