using JcfDocumentHub.Domain.News;

namespace JcfDocumentHub.Infrastructure.Seeding;

internal static class NewsSeedData
{
    public static IReadOnlyList<NewsArticle> Build()
    {
        DateTime now = DateTime.UtcNow;
        return new List<NewsArticle>
        {
            new()
            {
                Id = "news-001",
                Title = "Force Orders 2026 published",
                Summary = "New Force Orders effective 1 June 2026 are now available in the Document Hub.",
                Body = "## Force Orders 2026\n\nThe revised Force Orders take effect on **1 June 2026**. All officers must review the updated procedures for traffic stops and arrest documentation.",
                ImageUrl = "https://cdn.jcf.gov.jm/news/force-orders-2026.jpg",
                Category = "Force-wide",
                PublishedAtUtc = now.AddDays(-1),
                Author = "Commissioner of Police",
                Priority = NewsPriority.High
            },
            new()
            {
                Id = "news-002",
                Title = "Promotional examinations: study window opens",
                Summary = "Inspector and Sergeant promotional examination study materials are now searchable.",
                Body = "Officers preparing for the 2026 promotional examinations can locate study materials under the new **Promotional Study** category.",
                ImageUrl = "https://cdn.jcf.gov.jm/news/promotion-study.jpg",
                Category = "Operational",
                PublishedAtUtc = now.AddDays(-3),
                Author = "Training Branch",
                Priority = NewsPriority.Normal
            },
            new()
            {
                Id = "news-003",
                Title = "ICTD scheduled maintenance Sunday 02:00",
                Summary = "Document Hub will be briefly unavailable during a backup window.",
                Body = "ICTD will perform a routine backup of the document store between 02:00 and 02:30 on Sunday. The mobile application will continue to serve cached documents during the window.",
                ImageUrl = "https://cdn.jcf.gov.jm/news/maintenance.jpg",
                Category = "ICTD",
                PublishedAtUtc = now.AddHours(-12),
                Author = "ICTD",
                Priority = NewsPriority.Urgent
            }
        };
    }
}
