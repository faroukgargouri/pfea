using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;
using TrikiApi.Models;

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrdersController : ControllerBase
    {
        private readonly TrikiDbContext _context;

        public OrdersController(TrikiDbContext context)
        {
            _context = context;
        }
        
    [HttpPost]
public async Task<IActionResult> CreateOrder([FromBody] OrderCreationDto dto)
{
    var product = await _context.Products.FindAsync(dto.ProductId);
    if (product == null)
        return NotFound("Produit non trouvé");

    var order = new Order
    {
        UserId = dto.UserId,
        CreatedAt = DateTime.UtcNow,
        Total = dto.Quantity * product.Price,
        OrderItems = new List<OrderItem>
        {
            new OrderItem
            {
                ProductId = product.Id,
                Quantity = dto.Quantity,
                UnitPrice = (double)product.Price,
                TotalPrice = dto.Quantity * (double)product.Price,
                Product = product
            }
        }
    };

    _context.Orders.Add(order);
    await _context.SaveChangesAsync();

    return Ok(order);
}

    


        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetOrdersByUser(int userId)
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems)
                .Where(o => o.UserId == userId)
                .ToListAsync();

            var result = orders.Select(o => new
            {
                o.Id,
                o.Total,
                o.CreatedAt,
                Items = o.OrderItems.Select(oi => new
                {
                    oi.ProductId,
                    oi.Quantity,
                    oi.UnitPrice,
                    oi.TotalPrice
                })
            });

            return Ok(result);
        }
    }
}
