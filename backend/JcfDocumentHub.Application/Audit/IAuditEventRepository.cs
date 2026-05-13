using JcfDocumentHub.Domain.Audit;

namespace JcfDocumentHub.Application.Audit;

public interface IAuditEventRepository
{
    Task AppendAsync(AuditEvent auditEvent, CancellationToken cancellationToken);
}
