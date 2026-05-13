using JcfDocumentHub.Application.Audit;
using JcfDocumentHub.Domain.Audit;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JcfDocumentHub.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/audit")]
public sealed class AuditController : ControllerBase
{
    private readonly IAuditEventRepository auditEvents;

    public AuditController(IAuditEventRepository auditEvents)
    {
        this.auditEvents = auditEvents;
    }

    [HttpPost("access")]
    public async Task<IActionResult> RecordAccess(
        [FromBody] AccessEventRequest request,
        CancellationToken cancellationToken)
    {
        if (request is null || string.IsNullOrWhiteSpace(request.DocumentId))
        {
            return this.BadRequest(new { error = "documentId is required." });
        }
        if (!Enum.TryParse(request.EventType, ignoreCase: true, out AuditEventType eventType))
        {
            return this.BadRequest(new { error = $"Unknown eventType '{request.EventType}'." });
        }
        AuditEvent record = new()
        {
            TimestampUtc = request.TimestampUtc == default ? DateTime.UtcNow : request.TimestampUtc,
            DocumentId = request.DocumentId,
            DocumentTitle = string.Empty,
            EventType = eventType,
            OfficerEmail = this.User.Identity?.Name ?? string.Empty,
            ClientIp = this.HttpContext.Connection.RemoteIpAddress?.ToString() ?? string.Empty,
            AppVersion = this.Request.Headers["X-App-Version"].FirstOrDefault() ?? string.Empty,
            Outcome = AuditOutcome.Success
        };
        await this.auditEvents.AppendAsync(record, cancellationToken);
        return this.Accepted();
    }
}
