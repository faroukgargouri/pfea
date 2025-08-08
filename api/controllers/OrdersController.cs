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

        // ✅ POST /api/orders : Créer une commande
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

        // ✅ GET /api/orders/user/{userId} : Liste des commandes d’un utilisateur
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetOrdersByUser(int userId)
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
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
                    oi.Product.Name,
                    oi.Quantity,
                    oi.UnitPrice,
                    oi.TotalPrice
                })
            });

            return Ok(result);
        }

        // ✅ GET /api/orders/full : Toutes les commandes pour le Dashboard
        [HttpGet("full")]
        public async Task<IActionResult> GetAllOrdersWithDetails()
        {
            var orders = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .ToListAsync();

            var result = orders.Select(o => new
            {
                orderId = o.Id,
                client = o.User != null
                    ? (o.User.FirstName ?? "") + " " + (o.User.LastName ?? "")
                    : "Inconnu",
                createdAt = o.CreatedAt,
                total = o.TotalOrder,
                items = o.OrderItems.Select(oi => new
                {
                    productName = oi.Product?.Name ?? "Inconnu",
                    quantity = oi.Quantity,
                    unitPrice = oi.UnitPrice,
                    totalPrice = oi.TotalPrice
                }).ToList()
            });

            return Ok(result);
        }
    }
    // DTO utilisé pour créer une commande
    public class OrderCreationDto
    {
        public int UserId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
    }
}
