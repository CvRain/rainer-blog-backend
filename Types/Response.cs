namespace RainerBlog.Types;

public class BaseResponse
{
    public int Code { get; set; } = 200;
    public string Message { get; set; } = "";
    public string Result { get; set; } = "";
}