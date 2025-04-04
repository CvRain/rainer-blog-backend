using RainerBlog.Query;
using RainerBlog.Types;

namespace RainerBlog.Mutation;

public class BaseMutation
{
    public async Task<Book> AddBook(
        [Service] BlogDbContext context,
        string title,
        string author)
    {
        var book = new Book
        {
            Title = title,
            Author = author
        };

        context.Books.Add(book);
        await context.SaveChangesAsync();
        return book;
    }
}