﻿using var httpClient = new HttpClient();
var webApiUrl = Environment.GetEnvironmentVariable("WEBAPI_URL") ?? "http://localhost:8080";

var scenario = Scenario.Create("weather_forecast_scenario", async context =>
    {
        var request = new HttpRequestMessage(HttpMethod.Get, $"{webApiUrl}/weatherforecast");
        request.Headers.Add("Accept", "application/json");

        var response = await httpClient.SendAsync(request);

        return response.IsSuccessStatusCode
            ? Response.Ok()
            : Response.Fail();
    })
    .WithoutWarmUp()
    .WithLoadSimulations(
        Simulation.Inject(rate: 100,
            interval: TimeSpan.FromSeconds(1),
            during: TimeSpan.FromSeconds(30))
    );

NBomberRunner
    .RegisterScenarios(scenario)
    .Run();

Console.WriteLine("Load test completed.");