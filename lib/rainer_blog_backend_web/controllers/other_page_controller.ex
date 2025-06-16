defmodule RainerBlogBackendWeb.OtherPageController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackendWeb.Types.BaseResponse

  def main(conn, _params) do
    data = %{
      timestamp: :os.system_time(:millisecond),
      method: conn.method,
      host: conn.host,
      port: conn.port
    }
    response = BaseResponse.generate(200, "Hello world!", data)

    IO.puts(inspect(conn))

    json(conn, response)
  end
end
