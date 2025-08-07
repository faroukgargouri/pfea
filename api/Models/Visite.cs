using System.ComponentModel.DataAnnotations;

namespace TrikiApi.Models
{
    public class Visite
    {
        public int Id { get; set; }

        [Required]
        public string CodeVisite { get; set; } = string.Empty;

        [Required]
        public string? DateVisite { get; set; }

        [Required]
        public string CodeClient { get; set; } = string.Empty;

        [Required]
        public string RaisonSociale { get; set; } = string.Empty;

        public string CompteRendu { get; set; } = string.Empty;

        [Required]
        public int UserId { get; set; }

        public User? User { get; set; }
    }
}
