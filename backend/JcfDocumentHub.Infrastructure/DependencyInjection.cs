using JcfDocumentHub.Application.Audit;
using JcfDocumentHub.Application.Documents;
using JcfDocumentHub.Application.News;
using JcfDocumentHub.Application.WestOps;
using JcfDocumentHub.Infrastructure.Audit;
using JcfDocumentHub.Infrastructure.Documents;
using JcfDocumentHub.Infrastructure.News;
using JcfDocumentHub.Infrastructure.Persistence;
using JcfDocumentHub.Infrastructure.WestOps;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace JcfDocumentHub.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        MongoClassMapRegistry.Register();
        services.Configure<MongoSettings>(configuration.GetSection(MongoSettings.SectionName));
        services.AddSingleton<MongoContext>();
        services.AddScoped<ICategoryRepository, MongoCategoryRepository>();
        services.AddScoped<IDocumentRepository, MongoDocumentRepository>();
        services.AddScoped<IAuditEventRepository, MongoAuditEventRepository>();
        services.AddScoped<INewsRepository, MongoNewsRepository>();
        services.AddScoped<IWantedPersonRepository, MongoWantedPersonRepository>();
        services.AddScoped<IMissingPersonRepository, MongoMissingPersonRepository>();
        services.AddScoped<IStolenVehicleRepository, MongoStolenVehicleRepository>();
        services.AddScoped<ITrafficCodeRepository, MongoTrafficCodeRepository>();
        return services;
    }
}
