namespace TrikiApi.Models
{
    public class OrderCreationDto
    {
        public int UserId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
    }
}
