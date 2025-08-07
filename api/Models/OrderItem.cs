using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;


namespace TrikiApi.Models
{
    public class OrderItem
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public double UnitPrice { get; set; }
        public double TotalPrice { get; set; }
[JsonIgnore]
public Product? Product { get; set; }

    }
}
