using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;

[ApiController]
[Route("api/[controller]")]
public class DashboardController : ControllerBase
{
    private readonly TrikiDbContext _context;

    public DashboardController(TrikiDbContext context)
    {
        _context = context;
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        try
        {
            var nbProduits = await _context.Products.CountAsync();

            var nbClients = await _context.Users
                .Where(u => u.Role.ToLower() == "client" || u.Role.ToLower() == "représentant")
                .CountAsync();

            var totalVentes = await _context.Orders
                .Select(o => (decimal?)o.Total)
                .SumAsync() ?? 0;

            return Ok(new
            {
                produits = nbProduits,
                clients = nbClients,
                ventes = totalVentes
            });
        }
        catch (Exception ex)
        {
            // 🔍 Affiche l'erreur dans la console .NET (dotnet run)
            Console.WriteLine("Erreur dans GetStats : " + ex.Message);
            Console.WriteLine("StackTrace : " + ex.StackTrace);

            // 🔁 Retourne l'erreur détaillée au frontend (temporaire pour debug)
            return StatusCode(500, new
            {
                message = "Erreur serveur dans /dashboard/stats",
                details = ex.Message
            });
        }
    }
}
