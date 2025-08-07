using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;
using TrikiApi.Models; // Remplace YourNamespace par le vrai

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CartController : ControllerBase
    {
        private readonly TrikiDbContext _context;

        public CartController(TrikiDbContext context)
        {
            _context = context;
        }

        // ✅ Ajout au panier
        [HttpPost]
        public async Task<IActionResult> AddToCart([FromBody] CartItem item)
        {
            if (item == null || item.ProductId == 0 || item.UserId == 0 || item.Quantity <= 0)
                return BadRequest("Données invalides");

            var product = await _context.Products.FindAsync(item.ProductId);
            if (product == null)
                return NotFound("Produit non trouvé");

            item.Product = product;
            item.Price = product.Price;

            _context.CartItems.Add(item);
            await _context.SaveChangesAsync();

            return Ok(item);
        }

        // ✅ Liste des articles dans le panier par utilisateur
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<CartItem>>> GetCartItems(int userId)
        {
            var items = await _context.CartItems
                .Where(c => c.UserId == userId)
                .Include(c => c.Product)
                .ToListAsync();

            return Ok(items);
        }

        // ✅ Suppression d’un article du panier
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCartItem(int id)
        {
            var item = await _context.CartItems.FindAsync(id);
            if (item == null)
                return NotFound();

            _context.CartItems.Remove(item);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
