namespace JcfDocumentHub.Domain.Audit;

public sealed class AuditEvent
{
    public string Id { get; set; } = string.Empty;

    public DateTime TimestampUtc { get; set; }

    public string OfficerEmail { get; set; } = string.Empty;

    public string DocumentId { get; set; } = string.Empty;

    public string DocumentTitle { get; set; } = string.Empty;

    public AuditEventType EventType { get; set; }

    public string ClientIp { get; set; } = string.Empty;

    public string AppVersion { get; set; } = string.Empty;

    public AuditOutcome Outcome { get; set; }
}

public enum AuditEventType
{
    View,
    Download,
    Search,
    Login,
    Logout,
    FailedAuth,
    AccessDenied
}

public enum AuditOutcome
{
    Success,
    Denied
}
