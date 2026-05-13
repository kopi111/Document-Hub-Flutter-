namespace JcfDocumentHub.Application.Documents;

public sealed record SyncManifestEntry(
    string DocumentId,
    string Title,
    string CategoryId,
    string Sha256Hash,
    int VersionNumber,
    DateTime LastModifiedUtc,
    long FileSizeBytes);
