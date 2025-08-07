using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using TrikiApi.Data; // Ton namespace

var builder = WebApplication.CreateBuilder(args);

// ✅ Connexion base de données
builder.Services.AddDbContext<TrikiDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ✅ CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// ✅ Middleware dans le BON ORDRE
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// ✅ CORS en premier
app.UseCors("AllowAll");

// ❌ Commenter HTTPS redirection si test local avec IP
// app.UseHttpsRedirection();

app.UseAuthorization();
app.MapControllers();
app.Run();
