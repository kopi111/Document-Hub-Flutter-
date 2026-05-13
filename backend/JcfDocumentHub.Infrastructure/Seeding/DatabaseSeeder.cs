using JcfDocumentHub.Application.News;
using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Domain.News;
using JcfDocumentHub.Domain.WestOps;
using Microsoft.Extensions.Logging;

namespace JcfDocumentHub.Infrastructure.Seeding;

/// <summary>
///   Lazy seeder: populates News, WantedPersons, MissingPersons, StolenVehicles
///   and TrafficCodes only when their collections are empty. Idempotent.
/// </summary>
public sealed class DatabaseSeeder
{
    private readonly INewsRepository news;
    private readonly IWantedPersonRepository wanted;
    private readonly IMissingPersonRepository missing;
    private readonly IStolenVehicleRepository stolen;
    private readonly ITrafficCodeRepository codes;
    private readonly ILogger<DatabaseSeeder> log;

    public DatabaseSeeder(
        INewsRepository news,
        IWantedPersonRepository wanted,
        IMissingPersonRepository missing,
        IStolenVehicleRepository stolen,
        ITrafficCodeRepository codes,
        ILogger<DatabaseSeeder> log)
    {
        this.news = news;
        this.wanted = wanted;
        this.missing = missing;
        this.stolen = stolen;
        this.codes = codes;
        this.log = log;
    }

    public async Task SeedAsync(CancellationToken cancellationToken)
    {
        await SeedNewsAsync(cancellationToken);
        await SeedWantedAsync(cancellationToken);
        await SeedMissingAsync(cancellationToken);
        await SeedStolenAsync(cancellationToken);
        await SeedTrafficCodesAsync(cancellationToken);
    }

    private async Task SeedNewsAsync(CancellationToken cancellationToken)
    {
        if (await this.news.CountAsync(cancellationToken) > 0)
        {
            this.log.LogInformation("News collection already populated; skipping.");
            return;
        }
        IReadOnlyList<NewsArticle> articles = NewsSeedData.Build();
        foreach (NewsArticle article in articles)
        {
            await this.news.InsertAsync(article, cancellationToken);
        }
        this.log.LogInformation("Seeded {Count} news articles.", articles.Count);
    }

    private async Task SeedWantedAsync(CancellationToken cancellationToken)
    {
        if (await this.wanted.CountAsync(cancellationToken) > 0)
        {
            return;
        }
        IReadOnlyList<WantedPerson> persons = WestOpsSeedData.WantedPersons();
        await this.wanted.InsertManyAsync(persons, cancellationToken);
        this.log.LogInformation("Seeded {Count} wanted persons.", persons.Count);
    }

    private async Task SeedMissingAsync(CancellationToken cancellationToken)
    {
        if (await this.missing.CountAsync(cancellationToken) > 0)
        {
            return;
        }
        IReadOnlyList<MissingPerson> persons = WestOpsSeedData.MissingPersons();
        await this.missing.InsertManyAsync(persons, cancellationToken);
        this.log.LogInformation("Seeded {Count} missing persons.", persons.Count);
    }

    private async Task SeedStolenAsync(CancellationToken cancellationToken)
    {
        if (await this.stolen.CountAsync(cancellationToken) > 0)
        {
            return;
        }
        IReadOnlyList<StolenVehicle> vehicles = WestOpsSeedData.StolenVehicles();
        await this.stolen.InsertManyAsync(vehicles, cancellationToken);
        this.log.LogInformation("Seeded {Count} stolen vehicles.", vehicles.Count);
    }

    private async Task SeedTrafficCodesAsync(CancellationToken cancellationToken)
    {
        if (await this.codes.CountAsync(cancellationToken) > 0)
        {
            return;
        }
        IReadOnlyList<TrafficCode> records = WestOpsSeedData.TrafficCodes();
        await this.codes.InsertManyAsync(records, cancellationToken);
        this.log.LogInformation("Seeded {Count} traffic codes.", records.Count);
    }
}
