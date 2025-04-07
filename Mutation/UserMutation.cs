using Microsoft.EntityFrameworkCore;
using RainerBlog.Types;
using RainerBlog.Utils;

namespace RainerBlog.Mutation;

[ExtendObjectType(typeof(BaseMutation))]
public class UserMutation
{
    public async Task<CommonResponse<User>> RegisterUser(
        [Service] BlogDbContext context,
        string name,
        string email,
        string password)
    {
        if (User.UserExist(context))
        {
            return new CommonResponse<User>(data: new User())
            {
                Code = 403,
                Message = "User already exists",
                Result = "403Forbidden",
            };
        }
        
        if (!IsValidEmail(email))
        {
            return new CommonResponse<User>(data: new User())
            {
                Code = 400,
                Message = "Invalid email format",
                Result = "400BadRequest",
            };
        }
        
        var hashPassword = PasswordHasher.HashPassword(password);
        var user = new User(name, email, hashPassword);
        try
        {
            context.Users.Add(user);
            await context.SaveChangesAsync();
            return new CommonResponse<User>(data: user)
            {
                Code = 200,
                Message = "User registered successfully",
                Result = "200Ok",
            };
        }
        catch (DbUpdateException ex)
        {
            // return new RegisterUserPayload(null, $"Registration failed: {ex.InnerException?.Message}");
            return new CommonResponse<User>(data: new User())
            {
                Code = 500,
                Message = ex.InnerException?.Message ?? "Registration failed",
                Result = "500InternalServerError",
            };
        }
    }

    private static bool IsValidEmail(string email)
    {
        try
        {
            var address = new System.Net.Mail.MailAddress(email);
            return address.Address == email;
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            return false;
        }
    }
}