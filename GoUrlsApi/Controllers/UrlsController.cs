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
        private readonly GoUrlsDbContext _context;
        private readonly string[] _reservedWords;

        public UrlsController(GoUrlsDbContext context)
        {
            _context = context;
            
            // Read reserved words from environment variable - no fallback
            var reservedWordsStr = Environment.GetEnvironmentVariable("RESERVED_WORDS");
            if (string.IsNullOrEmpty(reservedWordsStr))
            {
                throw new InvalidOperationException("RESERVED_WORDS environment variable is not set");
            }
            
            _reservedWords = reservedWordsStr.Split(',', StringSplitOptions.RemoveEmptyEntries)
                                           .Select(w => w.Trim().ToLower())
                                           .ToArray();
        }

        [HttpGet("user")]
        public IActionResult GetCurrentUser()
        {
            var user = User.Identity?.Name ?? "Unknown User";
            return Ok(new { name = user });
        }

        [HttpGet("reserved-words")]
        public IActionResult GetReservedWords()
        {
            return Ok(new { reservedWords = _reservedWords });
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
        public async Task<IActionResult> RedirectToLongUrl(string shortName)
        {
            var entry = await _context.Urls.FirstOrDefaultAsync(u => u.ShortName == shortName);
            if (entry == null)
            {
                // Instead of 404, redirect to create page with shortName as parameter
                var createUrl = $"/create?shortName={Uri.EscapeDataString(shortName)}&available=true";
                return Redirect(createUrl);
            }
            
            // Perform HTTP redirect to the long URL
            return Redirect(entry.LongUrl);
        }

        [HttpGet("{shortName}")]
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
            // Validate against reserved words
            if (_reservedWords.Contains(entry.ShortName.Trim().ToLower()))
            {
                return BadRequest(new { 
                    error = "Reserved word", 
                    message = $"'{entry.ShortName}' is a reserved word and cannot be used as a short URL." 
                });
            }

            // Check if short name already exists
            var existingEntry = await _context.Urls.FirstOrDefaultAsync(u => u.ShortName.ToLower() == entry.ShortName.Trim().ToLower());
            if (existingEntry != null)
            {
                return BadRequest(new { 
                    error = "Duplicate", 
                    message = $"Short name '{entry.ShortName}' is already taken." 
                });
            }

            entry.Id = Guid.NewGuid();
            entry.ShortName = entry.ShortName.Trim();
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
