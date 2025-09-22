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
    }
}
