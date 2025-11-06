using System;
using System.ComponentModel.DataAnnotations;

namespace GoUrlsApi.Models
{
    public class UrlEntry
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public string ShortName { get; set; }

        [Required]
        public string LongUrl { get; set; }

        // User tracking and audit fields
        [Required]
        public string CreatedBy { get; set; } = "system";
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? UpdatedAt { get; set; }
        
        public string? UpdatedBy { get; set; }
        
        public bool IsSystemEntry { get; set; } = false;
    }
}
