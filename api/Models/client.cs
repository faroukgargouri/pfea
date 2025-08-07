namespace TrikiApi.Models
{
    public class Client
    {
        public int Id { get; set; }
        public string CodeClient { get; set; } = string.Empty;
        public string RaisonSociale { get; set; } = string.Empty;
        public string Telephone { get; set; } = string.Empty;
        public string Ville { get; set; } = string.Empty;

        // Relation correcte
        public int UserId { get; set; }
        public User? User { get; set; }
    }
}
