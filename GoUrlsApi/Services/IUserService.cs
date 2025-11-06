using GoUrlsApi.Models;

namespace GoUrlsApi.Services
{
    public interface IUserService
    {
        string GetCurrentUser();
        bool IsSystemUser();
        bool CanEditEntry(UrlEntry entry);
        bool CanDeleteEntry(UrlEntry entry);
        bool CanUserModifyEntry(string currentUser, UrlEntry entry);
        string GetAuthenticationMode();
    }
}