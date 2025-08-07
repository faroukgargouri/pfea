using Microsoft.EntityFrameworkCore;
using TrikiApi.Models;
namespace TrikiApi.Data
{
    public class TrikiDbContext : DbContext
    {
        public TrikiDbContext(DbContextOptions<TrikiDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Visite> Visites { get; set; }
        public DbSet<Client> Clients { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
public DbSet<Reclamation> Reclamations { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
           modelBuilder.Entity<Client>()
    .HasOne(c => c.User)
    .WithMany(u => u.Clients)
    .HasForeignKey(c => c.UserId)
    .OnDelete(DeleteBehavior.Restrict);
        }
        

    }
}