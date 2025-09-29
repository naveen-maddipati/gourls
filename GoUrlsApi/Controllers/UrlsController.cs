using Microsoft.EntityFrameworkCore;
using GoUrlsApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GoUrlsApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UrlsController : ControllerBase
    {
        [HttpGet("user")]
        public IActionResult GetCurrentUser()
        {
            var user = User.Identity?.Name ?? "Unknown User";
            return Ok(new { name = user });
        }
        private readonly GoUrlsDbContext _context;

        public UrlsController(GoUrlsDbContext context)
        {
            _context = context;
        }
        private static int NextId = 1;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<UrlEntry>>> GetAll()
        {
            var urls = await _context.Urls.ToListAsync();
            return Ok(urls);
        }

        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<UrlEntry>>> Search([FromQuery] string shortName)
        {
            var searchTerm = !string.IsNullOrEmpty(shortName) ? shortName : "";
            var query = _context.Urls.AsQueryable();
            if (!string.IsNullOrEmpty(searchTerm))
            {
                query = query.Where(e => EF.Functions.ILike(e.ShortName, $"%{searchTerm}%"));
            }
            var filtered = await query.ToListAsync();
            Console.WriteLine($"Returning {{filtered.Count}} results");
            return Ok(filtered);
        }

        [HttpGet("redirect/{shortName}")]
        public async Task<ActionResult<UrlEntry>> GetByShortName(string shortName)
        {
            var entry = await _context.Urls.FirstOrDefaultAsync(u => u.ShortName == shortName);
            if (entry == null)
            {
                return NotFound();
            }
            return Ok(entry);
        }

        [HttpPost]
        public async Task<ActionResult<UrlEntry>> Add([FromBody] UrlEntry entry)
        {
            entry.Id = Guid.NewGuid();
            _context.Urls.Add(entry);
            await _context.SaveChangesAsync();
            return Ok(entry);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update([FromBody] UrlEntry entry)
        {
            var existing = await _context.Urls.FindAsync(entry.Id);
            if (existing == null) return NotFound();
            existing.ShortName = entry.ShortName;
            existing.LongUrl = entry.LongUrl;
            await _context.SaveChangesAsync();
            return Ok();
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            var entry = await _context.Urls.FindAsync(id);
            if (entry == null) return NotFound();
            _context.Urls.Remove(entry);
            await _context.SaveChangesAsync();
            return Ok();
        }
    }
}
