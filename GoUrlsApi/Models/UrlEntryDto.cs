using System;

namespace GoUrlsApi.Models
{
    public class UrlEntryDto
    {
        public Guid Id { get; set; }
        public string ShortName { get; set; } = string.Empty;
        public string LongUrl { get; set; } = string.Empty;
        public string CreatedBy { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public string? UpdatedBy { get; set; }
        public bool IsSystemEntry { get; set; }
        
        // Permission flags calculated by backend
        public bool CanEdit { get; set; }
        public bool CanDelete { get; set; }
    }

    public class CreateUrlRequest
    {
        public string ShortName { get; set; } = string.Empty;
        public string LongUrl { get; set; } = string.Empty;
    }

    public class UpdateUrlRequest
    {
        public string ShortName { get; set; } = string.Empty;
        public string LongUrl { get; set; } = string.Empty;
    }
}