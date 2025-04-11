using Microsoft.EntityFrameworkCore.Query.Internal;
using RainerBlog.Types;
using RainerBlog.Utils;

namespace RainerBlog.Query;

[ExtendObjectType(typeof(BaseQuery))]
public class UserQuery
{
    // [UsePaging]
    // [UseProjection]
    // [UseFiltering]
    // [UseSorting]
    // public IQueryable<User> GetUsers([Service] BlogDbContext context)
    // {
    //     return context.Users;
    // }

    public CommonResponse<User> GetRandomUser()
    {
        var user = new User("test", "test@test.com", "this_is_password");
        var response = new CommonResponse<User>(data: user)
        {
            Code = 201,
            Message = "Random user",
            Result = "201Created",
        };
        return response;
    }

    public IQueryable<User> GetUserById([Service] BlogDbContext context, string id)
    {
        return context.Users.Where(u => u.Id == id);
    }

    public IQueryable<User> GetUserByEmail([Service] BlogDbContext context, string email)
    {
        return context.Users.Where(u => u.Email == email);
    }

    public BaseResponse UserExist([Service] BlogDbContext context)
    {
        var isExist = context.Users.Any();
        return new BaseResponse
        {
            Code = isExist ? 200 : 404,
            Message = isExist ? "User exist" : "User not exist",
            Result = isExist ? "200Ok" : "404NotFound"
        };
    }

    public record LoginToken(string? Token);

    public CommonResponse<LoginToken> UserLogin(
        [Service] BlogDbContext context,
        [Service] JwtService jwtService,
        string email, string password)
    {
        var user = context.Users.FirstOrDefault(u => u.Email == email);
        if (user == null)
        {
            return new CommonResponse<LoginToken>(data: new LoginToken(null))
            {
                Code = 404,
                Message = "User not exist",
                Result = "404NotFound"
            };
        }

        if (!PasswordHasher.VerifyPassword(user.Password, password))
        {
            return new CommonResponse<LoginToken>(data: new LoginToken(null))
            {
                Code = 401,
                Message = "Password error",
                Result = "401Unauthorized"
            };
        }

        var token = jwtService.GenerateToken(user);
        return new CommonResponse<LoginToken>(data: new LoginToken(token))
        {
            Code = 200,
            Message = "Login success",
            Result = "200Ok"
        };
    }
}