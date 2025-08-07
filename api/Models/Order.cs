using System.ComponentModel.DataAnnotations.Schema;

namespace TrikiApi.Models
{
    public class Order
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public User User { get; set; } = default!;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Total { get; set; }

        public DateTime CreatedAt { get; set; }

        public List<OrderItem> OrderItems { get; set; } = new();
        public decimal TotalOrder { get; internal set; }

    }
}
