namespace JcfDocumentHub.Domain.News;

public sealed class NewsArticle
{
    public string Id { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string Summary { get; set; } = string.Empty;

    public string Body { get; set; } = string.Empty;

    public string ImageUrl { get; set; } = string.Empty;

    public string Category { get; set; } = string.Empty;

    public DateTime PublishedAtUtc { get; set; }

    public string Author { get; set; } = string.Empty;

    public NewsPriority Priority { get; set; }
}

public enum NewsPriority
{
    Normal,
    High,
    Urgent
}
