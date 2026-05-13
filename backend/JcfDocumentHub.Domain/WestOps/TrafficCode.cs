namespace JcfDocumentHub.Domain.WestOps;

public sealed class TrafficCode
{
    public string Id { get; set; } = string.Empty;

    public string Code { get; set; } = string.Empty;

    public string Section { get; set; } = string.Empty;

    public string Offence { get; set; } = string.Empty;

    public decimal FineAmount { get; set; }

    public int DemeritPoints { get; set; }

    public string Statute { get; set; } = string.Empty;
}
