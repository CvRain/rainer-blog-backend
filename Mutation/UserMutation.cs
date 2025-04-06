using Microsoft.EntityFrameworkCore;
using RainerBlog.Types;
using RainerBlog.Utils;

namespace RainerBlog.Mutation;

[ExtendObjectType(typeof(BaseMutation))]
public class UserMutation
{
    public record RegisterUserPayload(User? User, string? Error);
    public async Task<RegisterUserPayload> RegisterUser(
        [Service] BlogDbContext context,
        string name,
        string email,
        string password)
    {
        if (!IsValidEmail(email))
        {
            return new RegisterUserPayload(null, "Invalid email");
        }
        
        //唯一性验证
        if (await context.Users.AnyAsync(u => u.Email == email))
        {
            return new RegisterUserPayload(null, "Email already exists");
        }

        if (await context.Users.AnyAsync(u => u.Name == name))
        {
            return new RegisterUserPayload(null, "Name already exists");
        }

        var hashPassword = PasswordHasher.HashPassword(password);
        var user = new User(name, email, hashPassword);
        try
        {
            context.Users.Add(user);
            await context.SaveChangesAsync();
            return new RegisterUserPayload(user, null);
        }
        catch (DbUpdateException ex)
        {
            return new RegisterUserPayload(null, $"Registration failed: {ex.InnerException?.Message}");
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