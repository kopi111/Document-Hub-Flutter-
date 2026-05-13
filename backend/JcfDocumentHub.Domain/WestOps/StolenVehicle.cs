namespace JcfDocumentHub.Domain.WestOps;

public sealed class StolenVehicle
{
    public string Id { get; set; } = string.Empty;

    public string Make { get; set; } = string.Empty;

    public string Model { get; set; } = string.Empty;

    public int? Year { get; set; }

    public string Color { get; set; } = string.Empty;

    public string LicensePlate { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public DateTime DateStolen { get; set; }

    public string LastKnownLocation { get; set; } = string.Empty;

    public string OwnerName { get; set; } = string.Empty;

    public string OwnerContact { get; set; } = string.Empty;

    public decimal RewardAmount { get; set; }

    public string Status { get; set; } = string.Empty;

    public bool IsVerified { get; set; }

    public int? ReporterUserId { get; set; }

    public string PhotoUrl { get; set; } = string.Empty;
}
