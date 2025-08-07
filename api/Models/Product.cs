using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;
using TrikiApi.Models;

namespace TrikiApi.Models
{
    public class Product
    {
        public int Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        public string ImageUrl { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        [Required]
        public string Category { get; set; } = string.Empty;

        [Required]
        public string Reference { get; set; } = string.Empty; // ✅ ajouté

        public int Stock { get; set; }

        public List<OrderItem> OrderItems { get; set; } = new();
    }
}
