using Microsoft.EntityFrameworkCore;
using RainerBlog.Types;

namespace RainerBlog;

public class BlogDbContext(DbContextOptions<BlogDbContext> options) : DbContext(options)
{
    public DbSet<Book> Books => Set<Book>();
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        //为user添加唯一性约束
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Name)
            .IsUnique();
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();
    }
}