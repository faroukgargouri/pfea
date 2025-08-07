using System;

namespace TrikiApi.Models // ✅ Attention à la casse exacte !
{
    public class Reclamation
    {
        public int Id { get; set; }
        public string Client { get; set; } = string.Empty;
        public string Telephone { get; set; } = string.Empty;
        public string Note { get; set; } = string.Empty;
        public string RetourLivraison { get; set; } = string.Empty;
        public DateTime DateReclamation { get; set; } = DateTime.Now;

        public int UserId { get; set; }
        public User? User { get; set; }
    }
}
