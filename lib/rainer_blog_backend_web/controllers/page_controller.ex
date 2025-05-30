defmodule RainerBlogBackendWeb.PageController do
  use RainerBlogBackendWeb, :controller

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _params) do
    #IO.puts("conn, #{inspect(conn)}")
    response = %{
      message: "Hello World",
      host: conn.host,
      method: conn.method,
      timestamp: DateTime.utc_now()
    }

    conn
    |> put_status(200)
    |> json(response)
  end
end
