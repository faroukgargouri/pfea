using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ClientController : ControllerBase
    {
        private readonly TrikiDbContext _db;
        public ClientController(TrikiDbContext db) => _db = db;

        // GET /api/client/user/3   → all clients owned by rep userId=3
        [HttpGet("user/{userId:int}")]
        public async Task<IActionResult> GetByUser(int userId)
        {
            var okUser = await _db.Users.AnyAsync(u => u.Id == userId);
            if (!okUser) return NotFound(new { message = "Utilisateur introuvable." });

            var rows = await _db.Clients
                .Where(c => c.UserId == userId)
                .OrderBy(c => c.RaisonSociale)
                .Select(c => new {
                    c.Id,
                    c.CodeClient,
                    c.RaisonSociale,
                    c.Telephone,
                    c.Ville,
                    c.UserId
                })
                .ToListAsync();

            return Ok(rows); // JSON camelCase by default
        }

        // optional: /api/client/search?userId=3&term=sfax
        [HttpGet("search")]
        public async Task<IActionResult> Search([FromQuery] int userId, [FromQuery] string term = "")
        {
            term = (term ?? "").Trim().ToLowerInvariant();
            var q = _db.Clients.Where(c => c.UserId == userId);

            if (!string.IsNullOrEmpty(term))
                q = q.Where(c =>
                    c.CodeClient.ToLower().Contains(term) ||
                    c.RaisonSociale.ToLower().Contains(term) ||
                    (c.Ville ?? "").ToLower().Contains(term));

            var rows = await q.OrderBy(c => c.RaisonSociale).Select(c => new {
                c.Id, c.CodeClient, c.RaisonSociale, c.Telephone, c.Ville, c.UserId
            }).ToListAsync();

            return Ok(rows);
        }
    }
}
