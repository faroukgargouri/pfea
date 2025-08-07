using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;
using TrikiApi.Models;
using System.ComponentModel.DataAnnotations;

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VisiteController : ControllerBase
    {
        private readonly TrikiDbContext _context;

        public VisiteController(TrikiDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<IActionResult> PostVisite([FromBody] Visite visite)
        {
            if (string.IsNullOrWhiteSpace(visite.CodeVisite) ||
                string.IsNullOrWhiteSpace(visite.DateVisite) ||
                string.IsNullOrWhiteSpace(visite.CodeClient) ||
                string.IsNullOrWhiteSpace(visite.RaisonSociale) ||
                string.IsNullOrWhiteSpace(visite.CompteRendu) ||
                visite.UserId == 0)
            {
                return BadRequest(new { message = "Champs obligatoires manquants ou invalides." });
            }

            _context.Visites.Add(visite);
            await _context.SaveChangesAsync();
            return Ok(visite);
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetVisitesByUser(int userId)
        {
            var visites = await _context.Visites
                .Where(v => v.UserId == userId)
                .ToListAsync();

            return Ok(visites);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutVisite(int id, [FromBody] Visite visite)
        {
            if (id != visite.Id)
                return BadRequest(new { message = "ID incohérent" });

            var existing = await _context.Visites.FindAsync(id);
            if (existing == null) return NotFound(new { message = "Visite non trouvée" });

            existing.CodeVisite = visite.CodeVisite;
            existing.DateVisite = visite.DateVisite;
            existing.CodeClient = visite.CodeClient;
            existing.RaisonSociale = visite.RaisonSociale;
            existing.CompteRendu = visite.CompteRendu;

            await _context.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVisite(int id)
        {
            var visite = await _context.Visites.FindAsync(id);
            if (visite == null) return NotFound(new { message = "Visite introuvable" });

            _context.Visites.Remove(visite);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Supprimée" });
        }
    }
}