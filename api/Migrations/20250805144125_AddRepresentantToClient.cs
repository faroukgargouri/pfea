using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace api.Migrations
{
    /// <inheritdoc />
    public partial class AddRepresentantToClient : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Clients_Users_UserId",
                table: "Clients");

            migrationBuilder.AlterColumn<string>(
                name: "DateVisite",
                table: "Visites",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RepresentantId",
                table: "Clients",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Reclamations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReclamationNo = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DateReclamation = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Representant = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Client = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Telephone = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    RetourLivraison = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Echange = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reclamations", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Clients_RepresentantId",
                table: "Clients",
                column: "RepresentantId");

            migrationBuilder.AddForeignKey(
                name: "FK_Clients_Users_RepresentantId",
                table: "Clients",
                column: "RepresentantId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Clients_Users_UserId",
                table: "Clients",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Clients_Users_RepresentantId",
                table: "Clients");

            migrationBuilder.DropForeignKey(
                name: "FK_Clients_Users_UserId",
                table: "Clients");

            migrationBuilder.DropTable(
                name: "Reclamations");

            migrationBuilder.DropIndex(
                name: "IX_Clients_RepresentantId",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "RepresentantId",
                table: "Clients");

            migrationBuilder.AlterColumn<string>(
                name: "DateVisite",
                table: "Visites",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddForeignKey(
                name: "FK_Clients_Users_UserId",
                table: "Clients",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
