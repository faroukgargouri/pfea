using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data;
using TrikiApi.Dtos;
using TrikiApi.Models;

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly TrikiDbContext _context;
        public AuthController(TrikiDbContext context) => _context = context;

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            var email = (dto.Email ?? "").Trim().ToLowerInvariant();
            if (string.IsNullOrWhiteSpace(email) ||
                string.IsNullOrWhiteSpace(dto.Password) ||
                string.IsNullOrWhiteSpace(dto.FirstName) ||
                string.IsNullOrWhiteSpace(dto.LastName))
                return BadRequest(new { message = "Champs obligatoires manquants." });

            var exists = await _context.Users.AnyAsync(u => u.Email == email);
            if (exists) return BadRequest(new { message = "Email déjà utilisé." });

            var user = new User
            {
                FirstName    = dto.FirstName!.Trim(),
                LastName     = dto.LastName!.Trim(),
                Email        = email,                 // stored lowercase
                PasswordHash = dto.Password!,         // SIMPLE version: plain text
                CodeSage     = string.IsNullOrWhiteSpace(dto.CodeSage) ? null : dto.CodeSage!.Trim(),
                Role         = string.IsNullOrWhiteSpace(dto.Role) ? "Représentant" : dto.Role!.Trim()
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new {
                id = user.Id, firstName = user.FirstName, lastName = user.LastName,
                email = user.Email, codeSage = user.CodeSage, role = user.Role
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var email = (dto.Email ?? "").Trim().ToLowerInvariant();
            var user  = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);

            if (user is null || user.PasswordHash != (dto.Password ?? ""))
                return Unauthorized(new { message = "Email ou mot de passe incorrect." });

            return Ok(new {
                id = user.Id, firstName = user.FirstName, lastName = user.LastName,
                email = user.Email, codeSage = user.CodeSage, role = user.Role
            });
        }
    }
}
