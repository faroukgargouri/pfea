using System.Collections.Generic;

namespace TrikiApi.Models // ✅ Majuscule T et A
{
    public class User
    {
        public int Id { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? PasswordHash { get; set; }
        public string? CodeSage { get; set; }
        public string? Role { get; set; }

        public ICollection<Client> Clients { get; set; } = new List<Client>();
    }
}
