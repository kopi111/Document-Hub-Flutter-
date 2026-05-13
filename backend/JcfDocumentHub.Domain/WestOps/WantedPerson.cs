namespace JcfDocumentHub.Domain.WestOps;

public sealed class WantedPerson
{
    public string Id { get; set; } = string.Empty;

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public string Alias { get; set; } = string.Empty;

    public string Gender { get; set; } = string.Empty;

    public DateTime? DateOfBirth { get; set; }

    public string CrimeDescription { get; set; } = string.Empty;

    public string PhotoUrl { get; set; } = string.Empty;

    public decimal RewardAmount { get; set; }

    public string ContactPhoneNumber { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;

    public bool IsVerified { get; set; }

    public int? ReporterUserId { get; set; }
}
