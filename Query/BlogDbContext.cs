using Microsoft.EntityFrameworkCore;
using RainerBlog.Types;

namespace RainerBlog.Query;

public class BlogDbContext(DbContextOptions<BlogDbContext> options) : DbContext(options)
{
    public DbSet<Book> Books => Set<Book>();
}