using JcfDocumentHub.Infrastructure;
using JcfDocumentHub.Infrastructure.Seeding;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

internal static class SeedRunner
{
    public static async Task RunAsync(string[] args)
    {
        IConfiguration configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile($"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development"}.json", optional: true)
            .AddEnvironmentVariables()
            .AddCommandLine(args)
            .Build();

        ServiceCollection services = new();
        services.AddLogging(builder => builder.AddConsole());
        services.AddInfrastructure(configuration);
        services.AddScoped<DatabaseSeeder>();

        await using ServiceProvider provider = services.BuildServiceProvider();
        using IServiceScope scope = provider.CreateScope();
        DatabaseSeeder seeder = scope.ServiceProvider.GetRequiredService<DatabaseSeeder>();
        ILogger<DatabaseSeeder> log = scope.ServiceProvider.GetRequiredService<ILogger<DatabaseSeeder>>();
        log.LogInformation("Seeding JCF Document Hub database (lazy: skips already-populated collections)...");
        await seeder.SeedAsync(CancellationToken.None);
        log.LogInformation("Seed complete.");
    }
}
