// File: api/controllers/ProductController.cs
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;

using TabletteNaoura.DTS.SQL;   // SqlServiceProduit
using TabletteNaoura.Models;    // Article

namespace TrikiApi.Controllers
{
    [ApiController]
    [Route("api/product")]
    public class ProductController : ControllerBase
    {
        private readonly SqlServiceProduit _sage = new();

        // GET /api/product
        // Query params:
        //   q               : search text (matches itmref or itmdes1)
        //   famille         : TCLCOD_0 (BON/GSS/CHA/GAS/PAK)
        //   sousFamille     : TSICOD_4
        //   includeSidiHeni : true/false (null = generic GetAll())
        //   page, pageSize
        [HttpGet]
        public IActionResult GetAll(
            [FromQuery] string? q,
            [FromQuery] string? famille,
            [FromQuery] string? sousFamille,
            [FromQuery] bool? includeSidiHeni,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            if (page < 1) page = 1;
            if (pageSize < 1 || pageSize > 200) pageSize = 50;

            IEnumerable<Article> rows = includeSidiHeni switch
            {
                true  => _sage.GetAllFilters(),
                false => _sage.GetAllFiltersSansProduitsSidiHeni(),
                _     => _sage.GetAll(),
            };

            // Structured filters via dedicated SQL (server-side)
            if (!string.IsNullOrWhiteSpace(famille) && string.IsNullOrWhiteSpace(sousFamille))
            {
                rows = _sage.GetProduitsParFamille(famille!);
            }
            else if (!string.IsNullOrWhiteSpace(famille) && !string.IsNullOrWhiteSpace(sousFamille))
            {
                rows = _sage.GetProduitsParSousFamille(famille!, sousFamille!);
            }

            // Text search — avoid ?. inside expression trees (fixes CS8072)
            if (!string.IsNullOrWhiteSpace(q))
            {
                var k = q.Trim();
                rows = rows
                    .AsEnumerable() // force LINQ-to-Objects so we can use IndexOf safely
                    .Where(a =>
                        ((a.itmdes1 ?? string.Empty).IndexOf(k, StringComparison.OrdinalIgnoreCase) >= 0) ||
                        ((a.itmref  ?? string.Empty).IndexOf(k, StringComparison.OrdinalIgnoreCase) >= 0))
                    .ToList();
            }

            var total = rows.Count();

            var items = rows
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(a => new
                {
                    Id          = a.itmref,                     // keep keys your UI expects
                    Name        = a.itmdes1,
                    Description = (string?)null,
                    ImageUrl    = $"/images/products/{a.image}.jpg", // or a.itmref if no images yet
                    Price       = a.prix,
                    Category    = a.Categorie,                  // TCLCOD_0
                    Reference   = a.itmref,
                    Stock       = 0
                })
                .ToList();

            return Ok(new { total, page, pageSize, items });
        }

        // GET /api/product/{id}
        [HttpGet("{id}")]
        public IActionResult GetById(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
                return BadRequest("Missing product id.");

            var a = _sage.Get(id);
            if (a is null) return NotFound();

            var item = new
            {
                Id          = a.itmref,
                Name        = a.itmdes1,
                Description = (string?)null,
                ImageUrl    = $"/images/products/{a.image}.jpg",
                Price       = a.prix,
                Category    = a.Categorie,
                Reference   = a.itmref,
                Stock       = 0
            };

            return Ok(item);
        }
    }
}
