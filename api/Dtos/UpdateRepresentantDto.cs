using System.ComponentModel.DataAnnotations;

namespace TrikiApi.Dtos
{
    public class UpdateRepresentantDto
    {
        [Required]
        public string FirstName { get; set; } = "";

        [Required]
        public string LastName { get; set; } = "";

        [Required]
        [EmailAddress]
        public string Email { get; set; } = "";

        public string? CodeSage { get; set; }
    }
}
