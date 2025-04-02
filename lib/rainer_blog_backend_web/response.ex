defmodule RainerBlogBackendWeb.Response do
  def base_response(code, status, result, data \\ nil) do
    %{
      code: code,
      status: status,
      result: result,
      data: data
    }
  end
end