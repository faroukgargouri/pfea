using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;
using TrikiApi.Models;

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductController : ControllerBase
    {
        private readonly TrikiDbContext _context;

        public ProductController(TrikiDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var products = await _context.Products.ToListAsync();
            return Ok(products);
        }
[HttpPost]
public async Task<IActionResult> Add([FromBody] Product product)
{
    if (!ModelState.IsValid)
        return BadRequest(ModelState);

    try
    {
        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        return Ok(product);
    }
    catch (Exception ex)
    {
        var inner = ex.InnerException?.Message ?? "aucune inner exception";
        Console.WriteLine("❌ ERREUR : " + ex.Message);
        Console.WriteLine("🔍 Inner Exception : " + inner);

        return StatusCode(500, new
        {
            message = "Erreur serveur",
            error = $"{ex.Message} - INNER: {inner}"
        });
    }
}


        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();

            _context.Products.Remove(product);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Supprimé" });
        }
    }
}