using Microsoft.OpenApi.Models;
using GoUrlsApi.Models;
using GoUrlsApi.Services;
using Microsoft.EntityFrameworkCore;



var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Add EF Core and PostgreSQL
builder.Services.AddDbContext<GoUrlsDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add User Management Services (Cross-Platform)
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IUserService, UserService>();

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Seed database on startup
try
{
    using var scope = app.Services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<GoUrlsDbContext>();
    
    // Ensure database is created
    await context.Database.EnsureCreatedAsync();
    
    // 🌱 CLEAN SLATE SEED DATA - 29 Entries with User Tracking (system entries)
    var seedData = new[]
    {
        // Development & Documentation
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440001"), ShortName = "nsval", LongUrl = "https://satori-ui-2025.beta.nuxeocloud.com/nuxeo/ui/#!/home", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440002"), ShortName = "nscon", LongUrl = "https://hyland.atlassian.net/wiki/spaces/NuxEng/pages/3574104075/Agile+Team+Agreements", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440003"), ShortName = "nsjira", LongUrl = "https://hyland.atlassian.net/jira/software/c/projects/NXSAT/boards/7076", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440004"), ShortName = "nsjiradb", LongUrl = "https://hyland.atlassian.net/jira/dashboards/21617", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440005"), ShortName = "nsrm", LongUrl = "https://hyland.atlassian.net/wiki/spaces/ANB/pages/3557852605/Nuxeo+Satori+-+Roadmap", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440006"), ShortName = "nuxdoc", LongUrl = "https://doc.nuxeo.com/nxdoc/rest-api/", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440007"), ShortName = "nuxdemos", LongUrl = "https://hyland.atlassian.net/wiki/spaces/NuxEng/pages/3645309080/Demo+of+Demos", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440008"), ShortName = "nuxhud", LongUrl = "https://hyland.atlassian.net/wiki/spaces/NuxEng/pages/3247836970/Nuxeo+Huddle+Meetings", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440009"), ShortName = "nuxcic", LongUrl = "https://hyland.atlassian.net/wiki/spaces/ANB/pages/3645964391/CIC+Workspace+and+Nuxeo+Satori", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440010"), ShortName = "nuxcsx", LongUrl = "https://hyland.atlassian.net/wiki/spaces/ANB/pages/3676210403/CSX+CIC+and+Nuxeo+Satori", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },

        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440011"), ShortName = "empteam", LongUrl = "https://hyland.atlassian.net/wiki/spaces/NuxEng/pages/3702687012/Empowered+Teams+Learning+Material", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440012"), ShortName = "satrm", LongUrl = "https://hyland.atlassian.net/wiki/spaces/RTP/pages/3192163911/Satori+Phased+Rollout+UX+Guidance", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440013"), ShortName = "satfaq", LongUrl = "https://hyland.atlassian.net/wiki/spaces/HDF/pages/2792457024/F.A.Q.", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440014"), ShortName = "satteam", LongUrl = "https://hyland.atlassian.net/wiki/spaces/HDF/pages/3061614970/Satori+Design+System+Team+Who+s+Who", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440015"), ShortName = "satgit", LongUrl = "https://github.com/HylandSoftware/satori/blob/main/packages/satori-devkit/getting-started.mdx", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440016"), ShortName = "satsb", LongUrl = "https://sturdy-barnacle-ozo3pr1.pages.github.io/?path=/docs/documentation-satori-ui-what-is-satori-ui--docs", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440017"), ShortName = "satfl", LongUrl = "https://hyland.atlassian.net/wiki/spaces/HDF/pages/2323121383/Satori+federated+libraries", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },

        
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440018"), ShortName = "pay", LongUrl = "https://mypayroll.myndsolution.com/Login.aspx?CID=HYLAND", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440019"), ShortName = "amex", LongUrl = "https://pages.hyland.com/TravelAndExpenses/Corporate-Credit-Card/AMEX-India-Program", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440020"), ShortName = "icims", LongUrl = "https://hyland.icims.com/platform?hashed=-1365527409", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440021"), ShortName = "mgrassist", LongUrl = "https://hylandex.qualtrics.com/portals/ui/manager-assist/app/manager-assist#/home", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440022"), ShortName = "uni", LongUrl = "https://university.hyland.com/learn/dashboard", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440023"), ShortName = "engage", LongUrl = "https://engage.cloud.microsoft/main/feed?domainRedirect=true", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440024"), ShortName = "hylight", LongUrl = "https://cloud.workhuman.com/static-apps/wh-host/#/", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440025"), ShortName = "workday", LongUrl = "https://www.myworkday.com/hyland/d/home.htmld", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440026"), ShortName = "hub", LongUrl = "https://hub.hyland.com/", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440027"), ShortName = "corner", LongUrl = "https://hyland.csod.com/ui/lms-learner-home/home?tab_page_id=-200300006&tab_id=-2", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440028"), ShortName = "medi", LongUrl = "https://portal.mediassist.in/Home.aspx", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true },
        new { Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440029"), ShortName = "benefits", LongUrl = "https://employee.benefitsyou.com/employeeenrollment.aspx", CreatedBy = "system", CreatedAt = DateTime.UtcNow, IsSystemEntry = true }
    };
    
    // Check which seed entries are missing and add them
    var missingSeedData = new List<UrlEntry>();
    
    foreach (var seedEntry in seedData)
    {
        var exists = await context.Urls.AnyAsync(u => u.Id == seedEntry.Id);
        if (!exists)
        {
            missingSeedData.Add(new UrlEntry
            {
                Id = seedEntry.Id,
                ShortName = seedEntry.ShortName,
                LongUrl = seedEntry.LongUrl,
                CreatedBy = seedEntry.CreatedBy,
                CreatedAt = seedEntry.CreatedAt,
                IsSystemEntry = seedEntry.IsSystemEntry,
                UpdatedAt = null,
                UpdatedBy = null
            });
        }
    }
    
    // Add missing seed data
    if (missingSeedData.Any())
    {
        await context.Urls.AddRangeAsync(missingSeedData);
        await context.SaveChangesAsync();
        
        Console.WriteLine($"✅ Added {missingSeedData.Count} missing seed URL entries:");
        foreach (var entry in missingSeedData)
        {
            Console.WriteLine($"   • {entry.ShortName} → {entry.LongUrl}");
        }
    }
    else
    {
        Console.WriteLine("✅ All seed data is present in database");
    }
}
catch (Exception ex)
{
    Console.WriteLine($"⚠️ Warning: Could not seed database: {ex.Message}");
    // Don't fail the application startup if seeding fails
}

// Configure the HTTP request pipeline.

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseCors();
app.UseHttpsRedirection();
app.MapControllers();

// Expose user identity endpoint
app.MapGet("/api/user", (HttpContext context) =>
{
    var user = context.User;
    if (user?.Identity?.IsAuthenticated == true)
    {
        return Results.Ok(new
        {
            user.Identity.Name,
            Claims = user.Claims.Select(c => new { c.Type, c.Value })
        });
    }
    return Results.Unauthorized();
});

// ...existing weatherforecast endpoint...
var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
