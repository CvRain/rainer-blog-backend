namespace RainerBlog.Types;

public class User
{
    public string Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
    [GraphQLIgnore] public string Password { get; private set; }
    public string Avatar { get; set; }
    public string Signature { get; set; }
    public string Background { get; set; }
    public long CreateTime { get; set; }
    public long UpdateTime { get; set; }

    public User()
    {
        Id = Guid.NewGuid().ToString();
        Name = "";
        Email = "";
        Password = "";
        Avatar = "";
        Signature = "";
        Background = "";
        CreateTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        UpdateTime = CreateTime;
    }

    public User(string name, string email, string password)
    {
        Id = Guid.NewGuid().ToString();
        Name = name;
        Email = email;
        Password = password;
        Avatar = "";
        Signature = "";
        Background = "";
        CreateTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        UpdateTime = CreateTime;
    }

    public static bool UserExist(BlogDbContext context)
    {
        return context.Users.Any();
    }
}