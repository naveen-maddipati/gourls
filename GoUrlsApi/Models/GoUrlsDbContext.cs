using Microsoft.EntityFrameworkCore;

namespace GoUrlsApi.Models
{
    public class GoUrlsDbContext : DbContext
    {
        public GoUrlsDbContext(DbContextOptions<GoUrlsDbContext> options) : base(options) { }
        public DbSet<UrlEntry> Urls { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // 🌱 No seed data needed here - handled by Application Startup seeding in Program.cs
            // This keeps it simple and ensures self-healing behavior
        }
    }
}
