namespace JcfDocumentHub.Domain.WestOps;

public sealed class MissingPerson
{
    public string Id { get; set; } = string.Empty;

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public string Gender { get; set; } = string.Empty;

    public DateTime? DateOfBirth { get; set; }

    public DateTime ReportedDate { get; set; }

    public string LastSeenLocation { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string PhotoUrl { get; set; } = string.Empty;

    public string ContactPerson { get; set; } = string.Empty;

    public string ContactPhoneNumber { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;

    public bool IsVerified { get; set; }

    public int? ReporterUserId { get; set; }
}
