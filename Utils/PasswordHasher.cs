using Microsoft.AspNetCore.Identity;

namespace RainerBlog.Utils;

public static class PasswordHasher
{
    private static readonly PasswordHasher<object> Hasher = new();

    public static string HashPassword(string password)
    {
        return Hasher.HashPassword(null!, password);
    }

    public static bool VerifyPassword(string hashedPassword, string providedPassword)
    {
        var result = Hasher.VerifyHashedPassword(null!, hashedPassword, providedPassword);
        return result == PasswordVerificationResult.Success;
    }
}