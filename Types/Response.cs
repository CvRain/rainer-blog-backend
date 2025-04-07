namespace RainerBlog.Types;

public class BaseResponse
{
    public int Code { get; set; } = 200;
    public string Message { get; set; } = "";
    public string Result { get; set; } = "";
}

public class CommonResponse<T> : BaseResponse
{
    public T Data { get; set; }
    
    public CommonResponse(T data)
    {
        Data = data;
    }
}