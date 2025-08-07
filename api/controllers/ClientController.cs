using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;
using TrikiApi.Models;

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ClientController : ControllerBase
    {
        private readonly TrikiDbContext _context;

        public ClientController(TrikiDbContext context)
        {
            _context = context;
        }
[HttpGet("user/{userId}")]
public async Task<IActionResult> GetClientsByUser(int userId)
{
    try
    {
        var clients = await _context.Clients
            .Where(c => c.UserId == userId)
            .ToListAsync();

        return Ok(clients);
    }
    catch (Exception ex)
    {
        return StatusCode(500, new { message = "Erreur interne", error = ex.Message });
    }
}


        [HttpGet("check/{codeClient}")]
        public IActionResult CheckClientExists(string codeClient)
        {
            var exists = _context.Clients.Any(c => c.CodeClient == codeClient);
            return exists ? Ok() : NotFound();
        }

        [HttpPost]
        public async Task<IActionResult> AddClient([FromBody] Client client)
        {
            if (_context.Clients.Any(c => c.CodeClient == client.CodeClient))
                return BadRequest(new { message = "Ce code client existe déjà." });

            _context.Clients.Add(client);
            await _context.SaveChangesAsync();
            return Ok(client);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateClient(int id, [FromBody] Client updated)
        {
            var client = await _context.Clients.FindAsync(id);
            if (client == null) return NotFound(new { message = "Client introuvable" });

            client.CodeClient = updated.CodeClient;
            client.RaisonSociale = updated.RaisonSociale;
            client.Telephone = updated.Telephone;
            client.Ville = updated.Ville;
            await _context.SaveChangesAsync();
            return Ok(client);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteClient(int id)
        {
            var client = await _context.Clients.FindAsync(id);
            if (client == null) return NotFound(new { message = "Client introuvable" });

            _context.Clients.Remove(client);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Client supprimé" });
        }
    }
}
