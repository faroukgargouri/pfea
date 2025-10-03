using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace TrikiApi.Models
{
    public class User
    {
        public int Id { get; set; }

        [Required, MaxLength(80)]
        public string FirstName { get; set; } = string.Empty;

        [Required, MaxLength(80)]
        public string LastName { get; set; } = string.Empty;

        [Required, EmailAddress, MaxLength(180)]
        public string Email { get; set; } = string.Empty;

        // 👉 plain text password
        [Required, MaxLength(100)]
        public string PasswordHash { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? CodeSage { get; set; }

        [Required, MaxLength(50)]
        public string Role { get; set; } = "Représentant";

        public ICollection<Client> Clients { get; set; } = new List<Client>();
    }
}
