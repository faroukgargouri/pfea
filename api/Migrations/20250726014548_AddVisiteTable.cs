using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace api.Migrations
{
    /// <inheritdoc />
    public partial class AddVisiteTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Visites",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CodeVisite = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DateVisite = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CodeClient = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    RaisonSociale = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CompteRendu = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Visites", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Visites");
        }
    }
}
