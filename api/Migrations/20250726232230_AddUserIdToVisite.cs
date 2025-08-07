using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace api.Migrations
{
    /// <inheritdoc />
    public partial class AddUserIdToVisite : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "DateVisite",
                table: "Visites",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "Visites",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_Visites_UserId",
                table: "Visites",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Visites_Users_UserId",
                table: "Visites",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Visites_Users_UserId",
                table: "Visites");

            migrationBuilder.DropIndex(
                name: "IX_Visites_UserId",
                table: "Visites");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "Visites");

            migrationBuilder.AlterColumn<string>(
                name: "DateVisite",
                table: "Visites",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);
        }
    }
}
