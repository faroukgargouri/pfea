using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;
using TrikiApi.Models;
using TrikiApi.Dtos;

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RepresentantController : ControllerBase
    {
        private readonly TrikiDbContext _context;

        public RepresentantController(TrikiDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var reps = await _context.Users
                .Where(u => u.Role == "Représentant")
                .Select(u => new
                {
                    u.Id,
                    u.FirstName,
                    u.LastName,
                    u.Email,
                    u.CodeSage,
                    u.Role
                })
                .ToListAsync();

            return Ok(reps);
        }
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateRepresentantDto dto)
        {
            if (!ModelState.IsValid)
            {
                // 👇 DEBUG pour voir ce qui pose problème
                var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
                return BadRequest(new { message = "Modèle invalide", errors });
            }

            var rep = await _context.Users.FindAsync(id);
            if (rep == null) return NotFound();

            rep.FirstName = dto.FirstName;
            rep.LastName = dto.LastName;
            rep.Email = dto.Email;
            rep.CodeSage = dto.CodeSage;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Représentant modifié avec succès" });
        }


        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var rep = await _context.Users.FindAsync(id);
            if (rep == null)
                return NotFound();

            _context.Users.Remove(rep);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Représentant supprimé avec succès" });
        }
        [HttpGet("by-representant")]
        public async Task<IActionResult> GetClientsGroupedByRepresentant()
        {
            try
            {
                var grouped = await _context.Users
                    .Where(u => u.Role == "Représentant")
                    .Include(u => u.Clients)
                    .ToListAsync();

                var result = grouped.Select(u => new
                {
                    RepresentantId = u.Id,
                    Representant = $"{u.FirstName} {u.LastName}",
                    Clients = u.Clients.Select(c => new
                    {
                        c.Id,
                        c.CodeClient,
                        c.RaisonSociale,
                        c.Telephone,
                        c.Ville
                    }).ToList()
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Erreur serveur",
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }
    }
}
