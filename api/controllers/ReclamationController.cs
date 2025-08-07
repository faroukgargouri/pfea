using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;
using TrikiApi.Models;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReclamationController : ControllerBase
    {
        private readonly TrikiDbContext _context;

        public ReclamationController(TrikiDbContext context)
        {
            _context = context;
        }

        // ✅ Ajouter une réclamation
        [HttpPost]
        public async Task<IActionResult> PostReclamation([FromBody] Reclamation reclamation)
        {
            if (reclamation == null)
                return BadRequest("Reclamation vide.");

            reclamation.DateReclamation = DateTime.Now;
            _context.Reclamations.Add(reclamation);
            await _context.SaveChangesAsync();
            return Ok(reclamation);
        }

        // ✅ Lister toutes les réclamations
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var reclamations = await _context.Reclamations
                .OrderByDescending(r => r.DateReclamation)
                .ToListAsync();
            return Ok(reclamations);
        }

        // ✅ Récupérer par utilisateur
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUserId(int userId)
        {
            var list = await _context.Reclamations
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.DateReclamation)
                .ToListAsync();

            return Ok(list);
        }
    }
}
