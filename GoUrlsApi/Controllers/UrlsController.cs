using Microsoft.EntityFrameworkCore;
using GoUrlsApi.Models;
using GoUrlsApi.Services;
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
        private readonly IUserService _userService;
        private readonly string[] _reservedWords;

        public UrlsController(GoUrlsDbContext context, IUserService userService)
        {
            _context = context;
            _userService = userService;
            
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
            var currentUser = _userService.GetCurrentUser();
            return Ok(new { 
                name = currentUser, 
                isAuthenticated = !string.IsNullOrEmpty(currentUser) && currentUser != "anonymous"
            });
        }

        [HttpGet("reserved-words")]
        public IActionResult GetReservedWords()
        {
            return Ok(new { reservedWords = _reservedWords });
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<UrlEntryDto>>> GetAll()
        {
            var urls = await _context.Urls.ToListAsync();
            var currentUser = _userService.GetCurrentUser();
            
            var urlDtos = urls.Select(url => new UrlEntryDto
            {
                Id = url.Id,
                ShortName = url.ShortName,
                LongUrl = url.LongUrl,
                CreatedBy = url.CreatedBy,
                CreatedAt = url.CreatedAt,
                UpdatedAt = url.UpdatedAt,
                UpdatedBy = url.UpdatedBy,
                IsSystemEntry = url.IsSystemEntry,
                CanEdit = _userService.CanUserModifyEntry(currentUser, url),
                CanDelete = _userService.CanUserModifyEntry(currentUser, url)
            }).ToList();
            
            return Ok(urlDtos);
        }

        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<UrlEntryDto>>> Search([FromQuery] string shortName)
        {
            var searchTerm = !string.IsNullOrEmpty(shortName) ? shortName : "";
            var query = _context.Urls.AsQueryable();
            if (!string.IsNullOrEmpty(searchTerm))
            {
                query = query.Where(e => EF.Functions.ILike(e.ShortName, $"%{searchTerm}%"));
            }
            var filtered = await query.ToListAsync();
            var currentUser = _userService.GetCurrentUser();
            
            var urlDtos = filtered.Select(url => new UrlEntryDto
            {
                Id = url.Id,
                ShortName = url.ShortName,
                LongUrl = url.LongUrl,
                CreatedBy = url.CreatedBy,
                CreatedAt = url.CreatedAt,
                UpdatedAt = url.UpdatedAt,
                UpdatedBy = url.UpdatedBy,
                IsSystemEntry = url.IsSystemEntry,
                CanEdit = _userService.CanUserModifyEntry(currentUser, url),
                CanDelete = _userService.CanUserModifyEntry(currentUser, url)
            }).ToList();
            
            Console.WriteLine($"Returning {urlDtos.Count} results");
            return Ok(urlDtos);
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
        public async Task<ActionResult<UrlEntryDto>> GetByShortName(string shortName)
        {
            var entry = await _context.Urls.FirstOrDefaultAsync(u => u.ShortName == shortName);
            if (entry == null)
            {
                return NotFound();
            }
            
            var currentUser = _userService.GetCurrentUser();
            var urlDto = new UrlEntryDto
            {
                Id = entry.Id,
                ShortName = entry.ShortName,
                LongUrl = entry.LongUrl,
                CreatedBy = entry.CreatedBy,
                CreatedAt = entry.CreatedAt,
                UpdatedAt = entry.UpdatedAt,
                UpdatedBy = entry.UpdatedBy,
                IsSystemEntry = entry.IsSystemEntry,
                CanEdit = _userService.CanUserModifyEntry(currentUser, entry),
                CanDelete = _userService.CanUserModifyEntry(currentUser, entry)
            };
            
            return Ok(urlDto);
        }

        [HttpPost]
        public async Task<ActionResult<UrlEntryDto>> Add([FromBody] CreateUrlRequest request)
        {
            // Validate against reserved words
            if (_reservedWords.Contains(request.ShortName.Trim().ToLower()))
            {
                return BadRequest(new { 
                    error = "Reserved word", 
                    message = $"'{request.ShortName}' is a reserved word and cannot be used as a short URL." 
                });
            }

            // Check if short name already exists
            var existingEntry = await _context.Urls.FirstOrDefaultAsync(u => u.ShortName.ToLower() == request.ShortName.Trim().ToLower());
            if (existingEntry != null)
            {
                return BadRequest(new { 
                    error = "Duplicate", 
                    message = $"Short name '{request.ShortName}' is already taken." 
                });
            }

            var currentUser = _userService.GetCurrentUser();
            var entry = new UrlEntry
            {
                Id = Guid.NewGuid(),
                ShortName = request.ShortName.Trim(),
                LongUrl = request.LongUrl,
                CreatedBy = currentUser,
                CreatedAt = DateTime.UtcNow,
                IsSystemEntry = false,
                UpdatedAt = null,
                UpdatedBy = null
            };

            _context.Urls.Add(entry);
            await _context.SaveChangesAsync();
            
            var urlDto = new UrlEntryDto
            {
                Id = entry.Id,
                ShortName = entry.ShortName,
                LongUrl = entry.LongUrl,
                CreatedBy = entry.CreatedBy,
                CreatedAt = entry.CreatedAt,
                UpdatedAt = entry.UpdatedAt,
                UpdatedBy = entry.UpdatedBy,
                IsSystemEntry = entry.IsSystemEntry,
                CanEdit = _userService.CanUserModifyEntry(currentUser, entry),
                CanDelete = _userService.CanUserModifyEntry(currentUser, entry)
            };
            
            return Ok(urlDto);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<UrlEntryDto>> Update(Guid id, [FromBody] UpdateUrlRequest request)
        {
            var existing = await _context.Urls.FindAsync(id);
            if (existing == null) 
                return NotFound();
            
            var currentUser = _userService.GetCurrentUser();
            
            // Check if user can modify this entry
            if (!_userService.CanUserModifyEntry(currentUser, existing))
            {
                return Forbid("You don't have permission to modify this URL entry.");
            }
            
            // Validate against reserved words (if shortName is being changed)
            if (request.ShortName.Trim().ToLower() != existing.ShortName.ToLower() && 
                _reservedWords.Contains(request.ShortName.Trim().ToLower()))
            {
                return BadRequest(new { 
                    error = "Reserved word", 
                    message = $"'{request.ShortName}' is a reserved word and cannot be used as a short URL." 
                });
            }

            // Check if short name already exists (if shortName is being changed)
            if (request.ShortName.Trim().ToLower() != existing.ShortName.ToLower())
            {
                var duplicateEntry = await _context.Urls.FirstOrDefaultAsync(u => 
                    u.Id != id && u.ShortName.ToLower() == request.ShortName.Trim().ToLower());
                if (duplicateEntry != null)
                {
                    return BadRequest(new { 
                        error = "Duplicate", 
                        message = $"Short name '{request.ShortName}' is already taken." 
                    });
                }
            }

            existing.ShortName = request.ShortName.Trim();
            existing.LongUrl = request.LongUrl;
            existing.UpdatedAt = DateTime.UtcNow;
            existing.UpdatedBy = currentUser;
            
            await _context.SaveChangesAsync();
            
            var urlDto = new UrlEntryDto
            {
                Id = existing.Id,
                ShortName = existing.ShortName,
                LongUrl = existing.LongUrl,
                CreatedBy = existing.CreatedBy,
                CreatedAt = existing.CreatedAt,
                UpdatedAt = existing.UpdatedAt,
                UpdatedBy = existing.UpdatedBy,
                IsSystemEntry = existing.IsSystemEntry,
                CanEdit = _userService.CanUserModifyEntry(currentUser, existing),
                CanDelete = _userService.CanUserModifyEntry(currentUser, existing)
            };
            
            return Ok(urlDto);
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            var entry = await _context.Urls.FindAsync(id);
            if (entry == null) 
                return NotFound();
            
            var currentUser = _userService.GetCurrentUser();
            
            // Check if user can delete this entry
            if (!_userService.CanUserModifyEntry(currentUser, entry))
            {
                return Forbid("You don't have permission to delete this URL entry.");
            }
            
            _context.Urls.Remove(entry);
            await _context.SaveChangesAsync();
            return Ok();
        }
    }
}
