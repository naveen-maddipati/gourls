using GoUrlsApi.Models;
using Microsoft.AspNetCore.Http;

namespace GoUrlsApi.Services
{
    public class UserService : IUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IConfiguration _configuration;

        public UserService(IHttpContextAccessor httpContextAccessor, IConfiguration configuration)
        {
            _httpContextAccessor = httpContextAccessor;
            _configuration = configuration;
        }

        public string GetCurrentUser()
        {
            var context = _httpContextAccessor.HttpContext;
            
            // Priority order for determining current user (CROSS-PLATFORM):
            // 1. Custom header (X-User-Name) - for development/testing on any OS
            // 2. Environment variable (CURRENT_USER) - for containers and local development
            // 3. Configuration value - for explicit user setting
            // 4. System username (OS-agnostic) - fallback for local development
            // 5. Windows Authentication (User.Identity.Name) - if available in production
            // 6. Default to "anonymous"

            // 1. Try custom header (preferred for development - works on all OS)
            if (context?.Request?.Headers?.ContainsKey("X-User-Name") == true)
            {
                var headerUser = context.Request.Headers["X-User-Name"].FirstOrDefault();
                if (!string.IsNullOrEmpty(headerUser))
                {
                    return SanitizeUsername(headerUser);
                }
            }

            // 2. Try environment variable (works on all OS)
            var envUser = Environment.GetEnvironmentVariable("CURRENT_USER");
            if (!string.IsNullOrEmpty(envUser))
            {
                return SanitizeUsername(envUser);
            }

            // 3. Try configuration (works on all OS)
            var configUser = _configuration["Authentication:DefaultUser"];
            if (!string.IsNullOrEmpty(configUser))
            {
                return SanitizeUsername(configUser);
            }

            // 4. Try system username (cross-platform fallback)
            try
            {
                var systemUser = GetSystemUsername();
                if (!string.IsNullOrEmpty(systemUser))
                {
                    return SanitizeUsername(systemUser);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Warning: Could not determine system username: {ex.Message}");
            }

            // 5. Try Windows Authentication (if available)
            if (context?.User?.Identity?.IsAuthenticated == true && 
                !string.IsNullOrEmpty(context.User.Identity.Name))
            {
                return SanitizeUsername(context.User.Identity.Name);
            }

            // 6. Default fallback
            return "anonymous";
        }

        public bool IsSystemUser()
        {
            return GetCurrentUser().Equals("system", StringComparison.OrdinalIgnoreCase);
        }

        public bool CanEditEntry(UrlEntry entry)
        {
            // System entries cannot be edited by anyone
            if (entry.IsSystemEntry)
            {
                return false;
            }

            var currentUser = GetCurrentUser();
            
            // Users can only edit their own entries
            return entry.CreatedBy.Equals(currentUser, StringComparison.OrdinalIgnoreCase);
        }

        public bool CanDeleteEntry(UrlEntry entry)
        {
            // System entries cannot be deleted by anyone
            if (entry.IsSystemEntry)
            {
                return false;
            }

            var currentUser = GetCurrentUser();
            
            // Users can only delete their own entries
            return entry.CreatedBy.Equals(currentUser, StringComparison.OrdinalIgnoreCase);
        }

        public string GetAuthenticationMode()
        {
            return _configuration["Authentication:Mode"] ?? "development";
        }

        private static string SanitizeUsername(string username)
        {
            if (string.IsNullOrEmpty(username))
                return "anonymous";

            // Remove domain part if present (DOMAIN\username -> username)
            if (username.Contains('\\'))
            {
                username = username.Split('\\').Last();
            }

            // Remove @domain.com if present
            if (username.Contains('@'))
            {
                username = username.Split('@').First();
            }

            return username.ToLowerInvariant().Trim();
        }

        private static string GetSystemUsername()
        {
            // Cross-platform method to get current system user
            try
            {
                // Method 1: Environment.UserName (works on Windows, macOS, Linux)
                var envUsername = Environment.UserName;
                if (!string.IsNullOrEmpty(envUsername))
                {
                    return envUsername;
                }

                // Method 2: Environment variables (cross-platform fallbacks)
                var username = Environment.GetEnvironmentVariable("USER") ??           // Unix/Linux/macOS
                              Environment.GetEnvironmentVariable("USERNAME") ??        // Windows
                              Environment.GetEnvironmentVariable("LOGNAME");          // Some Unix systems

                if (!string.IsNullOrEmpty(username))
                {
                    return username;
                }

                // Method 3: System.Security.Principal (Windows only, but safe fallback)
                if (OperatingSystem.IsWindows())
                {
                    try
                    {
                        var identity = System.Security.Principal.WindowsIdentity.GetCurrent();
                        if (identity?.Name != null)
                        {
                            return identity.Name;
                        }
                    }
                    catch
                    {
                        // Ignore Windows-specific errors on other platforms
                    }
                }

                return string.Empty;
            }
            catch
            {
                return string.Empty;
            }
        }

        public bool CanUserModifyEntry(string currentUser, UrlEntry entry)
        {
            // System entries cannot be modified by regular users
            if (entry.IsSystemEntry && currentUser != "system")
            {
                return false;
            }

            // Users can only modify their own entries (unless they're system)
            if (currentUser == "system")
            {
                return true;
            }

            return string.Equals(entry.CreatedBy, currentUser, StringComparison.OrdinalIgnoreCase);
        }
    }
}