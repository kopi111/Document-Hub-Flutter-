using JcfDocumentHub.Application.Audit;
using JcfDocumentHub.Domain.Audit;
using JcfDocumentHub.Infrastructure.Persistence;

namespace JcfDocumentHub.Infrastructure.Audit;

public sealed class MongoAuditEventRepository : IAuditEventRepository
{
    private readonly MongoContext context;

    public MongoAuditEventRepository(MongoContext context)
    {
        this.context = context;
    }

    public Task AppendAsync(AuditEvent auditEvent, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(auditEvent);
        if (string.IsNullOrWhiteSpace(auditEvent.Id))
        {
            auditEvent.Id = Guid.NewGuid().ToString("N");
        }
        return this.context.AuditEvents.InsertOneAsync(auditEvent, cancellationToken: cancellationToken);
    }
}
