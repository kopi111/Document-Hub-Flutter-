using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace JcfDocumentHub.Api.Tests;

public sealed class HealthEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> factory;

    public HealthEndpointTests(WebApplicationFactory<Program> factory)
    {
        this.factory = factory;
    }

    [Fact]
    public async Task Get_Health_Returns200AndOkPayload()
    {
        HttpClient client = this.factory.CreateClient();
        HttpResponseMessage response = await client.GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        string body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"status\":\"ok\"", body);
        Assert.Contains("JCF Document Hub API", body);
    }
}
