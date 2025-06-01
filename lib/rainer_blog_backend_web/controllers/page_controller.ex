defmodule RainerBlogBackendWeb.PageController do
  alias RainerBlogBackendWeb.Types.BaseResponse
  use RainerBlogBackendWeb, :controller

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _params) do
    data = %{
      timestamp: DateTime.utc_now(),
      host: conn.host,
      method: conn.method
    }

    response = BaseResponse.generate(200, "Hello world", data)

    conn
    |> put_status(response.code)
    |> json(response)
  end
end
