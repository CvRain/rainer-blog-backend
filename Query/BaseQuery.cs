using RainerBlog.Types;

namespace RainerBlog.Query;

public class BaseQuery
{
    [UseProjection]
    [UseFiltering]
    [UseSorting]
    public IQueryable<Book> GetBooks([Service] BlogDbContext context)
    {
        return context.Books;
    }
}