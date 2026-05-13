namespace JcfDocumentHub.Domain.Documents;

public sealed class Category
{
    public string Id { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string RequiredAdGroup { get; set; } = string.Empty;

    public int DocumentCount { get; set; }
}
