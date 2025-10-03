using Microsoft.EntityFrameworkCore;
using TrikiApi.Models;

namespace TrikiApi.Data
{
    public class TrikiDbContext : DbContext
    {
        public TrikiDbContext(DbContextOptions<TrikiDbContext> options) : base(options) { }

        public DbSet<User> Users => Set<User>();
        public DbSet<Client> Clients => Set<Client>(); // ⬅️ add this

        protected override void OnModelCreating(ModelBuilder mb)
        {
            mb.Entity<User>().HasIndex(u => u.Email).IsUnique();
            mb.Entity<Client>().HasIndex(c => new { c.CodeClient, c.UserId }).IsUnique();

            base.OnModelCreating(mb);
        }
    }
}
