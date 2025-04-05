using RainerBlog.Types;

namespace RainerBlog.Query;

[ExtendObjectType(typeof(BaseQuery))]
public class UserQuery
{
    [UsePaging]
    [UseProjection]
    [UseFiltering]
    [UseSorting]
    public IQueryable<User> GetUsers([Service] BlogDbContext context)
    {
        return context.Users;
    }
}