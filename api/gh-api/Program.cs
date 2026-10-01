var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/api/gh-api/hello", () => Results.Ok(new HelloResponse("Hello, world!")));

app.Run();

public sealed record HelloResponse(string Message);

public partial class Program { }
