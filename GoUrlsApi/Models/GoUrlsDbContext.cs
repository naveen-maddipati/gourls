using Microsoft.EntityFrameworkCore;

namespace GoUrlsApi.Models
{
    public class GoUrlsDbContext : DbContext
    {
        public GoUrlsDbContext(DbContextOptions<GoUrlsDbContext> options) : base(options) { }
        public DbSet<UrlEntry> Urls { get; set; }
    }
}
