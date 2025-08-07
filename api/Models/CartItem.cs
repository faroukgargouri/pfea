using TrikiApi.Models;

public class CartItem
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public Product Product { get; set; } = null!;
    public int Quantity { get; set; }
    public int UserId { get; set; }

    // ✅ Ajout du champ Price
    public decimal Price { get; set; }
}
