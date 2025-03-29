defmodule RainerBlogBackendWeb.HelloController do
  use RainerBlogBackendWeb, :controller

  def hello(conn, _params) do
    response = %{
      code: 200,
      message: "Hello World!",
      result: "200Ok",
      timestamp: DateTime.utc_now()
    }

    json(conn, response)
  end

  def echo(conn, params) do
    response =
      with {:ok, msg} <- Map.fetch(params, :msg) do
        %{
          code: 200,
          message: msg,
          result: "200Ok",
          timestamp: DateTime.utc_now()
        }
      else
        _ ->
          %{
            code: 400,
            message: "Invalid params",
            result: "400BadRequest",
            timestamp: DateTime.utc_now()
          }
      end

    json(conn, response)
  end
end
