namespace JcfDocumentHub.Domain.Documents;

public sealed class PolicyDocument
{
    public string Id { get; set; } = string.Empty;

    public string CategoryId { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public long FileSizeBytes { get; set; }

    public DateTime LastModifiedUtc { get; set; }

    public string Sha256Hash { get; set; } = string.Empty;

    public int VersionNumber { get; set; }

    public string StoragePath { get; set; } = string.Empty;
}
