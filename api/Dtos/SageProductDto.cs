// DTOs/SageProductDto.cs
namespace TrikiApi.DTOs
{
    public class SageProductDto
    {
        public string Reference  { get; set; } = string.Empty; // Sage: CodeArticle
        public string Name       { get; set; } = string.Empty; // Sage: DesArticle
        public string Category   { get; set; } = string.Empty; // Sage: Gamme
        public decimal Price     { get; set; } = 0m;           // TODO: map when you add price query
        public int Stock         { get; set; } = 0;            // TODO: map when you add stock query
        public string ImageUrl   { get; set; } = string.Empty; // e.g. /images/products/{ref}.jpg
        public string? Description { get; set; }
    }
}
