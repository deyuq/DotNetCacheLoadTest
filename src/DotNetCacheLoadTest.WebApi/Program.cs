using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Redis connection
var redisConnectionString = builder.Configuration.GetValue<string>("Redis:ConnectionString")
                            ?? Environment.GetEnvironmentVariable("REDIS_CONNECTION");
Console.WriteLine($"{redisConnectionString}");
var redis = ConnectionMultiplexer.Connect(redisConnectionString!);
var db = redis.GetDatabase();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapGet("/redis/{key}", async (string key) =>
    {
        var value = await db.StringGetAsync(key);
        if (value.IsNullOrEmpty)
        {
            Console.WriteLine($"Key not found: {key}");
            return Results.NotFound();
        }

        return Results.Ok(value.ToString());
    })
    .WithName("GetRedisValue")
    .WithOpenApi();

Console.WriteLine("Application started. Listening for requests...");
app.Run();