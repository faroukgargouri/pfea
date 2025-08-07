using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace api.Migrations
{
    /// <inheritdoc />
    public partial class AddReferenceToProduct : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Ref",
                table: "Products",
                newName: "Reference");

            migrationBuilder.RenameColumn(
                name: "Designation",
                table: "Products",
                newName: "Name");

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Products",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Description",
                table: "Products");

            migrationBuilder.RenameColumn(
                name: "Reference",
                table: "Products",
                newName: "Ref");

            migrationBuilder.RenameColumn(
                name: "Name",
                table: "Products",
                newName: "Designation");
        }
    }
}
