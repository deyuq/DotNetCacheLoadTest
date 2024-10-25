using var httpClient = new HttpClient();
var webApiUrl = Environment.GetEnvironmentVariable("WEBAPI_URL") ?? "http://localhost:5283";

var scenario = Scenario.Create("redis_scenario", async context =>
    {
        var request = new HttpRequestMessage(HttpMethod.Get, $"{webApiUrl}/redis/test_key");
        request.Headers.Add("Accept", "application/json");

        var response = await httpClient.SendAsync(request);

        return response.IsSuccessStatusCode
            ? Response.Ok()
            : Response.Fail();
    })
    .WithoutWarmUp()
    .WithLoadSimulations(
                Simulation.Inject(rate: 600, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30))
               // Simulation.Inject(rate: 1500, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30))
            );

NBomberRunner
    .RegisterScenarios(scenario)
    .Run();

Console.WriteLine("Load test completed.");