using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoUrlsApi.Migrations
{
    /// <inheritdoc />
    public partial class AddUserManagementColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Urls",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "NOW()");

            migrationBuilder.AddColumn<string>(
                name: "CreatedBy",
                table: "Urls",
                type: "text",
                nullable: false,
                defaultValue: "system");

            migrationBuilder.AddColumn<bool>(
                name: "IsSystemEntry",
                table: "Urls",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Urls",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UpdatedBy",
                table: "Urls",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Urls");

            migrationBuilder.DropColumn(
                name: "CreatedBy",
                table: "Urls");

            migrationBuilder.DropColumn(
                name: "IsSystemEntry",
                table: "Urls");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Urls");

            migrationBuilder.DropColumn(
                name: "UpdatedBy",
                table: "Urls");
        }
    }
}
