namespace JcfDocumentHub.Application.Audit;

public sealed record AccessEventRequest(
    string DocumentId,
    string EventType,
    DateTime TimestampUtc);
