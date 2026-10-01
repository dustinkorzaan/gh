using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Gh.Api.Tests;

public sealed class HelloEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public HelloEndpointTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetHelloReturnsTheGreeting()
    {
        // AC1
        using var response = await _client.GetAsync("/api/gh-api/hello");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<HelloResponse>();
        Assert.NotNull(body);
        Assert.Equal("Hello, world!", body.Message);
    }

    private sealed record HelloResponse(string Message);
}
