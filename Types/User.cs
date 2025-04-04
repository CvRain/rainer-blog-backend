namespace RainerBlog.Types;

public class User
{
    public string Name { get; set; }
    public string Email { get; set; }
    public string Password { get; set; }
    public string Avator { get; set; }
    public string Signature { get; set; }
    public string Background { get; set; }
    public int CreateTime { get; set; }
    public int UpdateTime { get; set; }
}