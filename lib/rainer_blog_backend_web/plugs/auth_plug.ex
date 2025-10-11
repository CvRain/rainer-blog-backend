defmodule RainerBlogBackendWeb.AuthPlug do
  import Plug.Conn
  alias RainerBlogBackendWeb.Types.BaseResponse

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_token(conn) do
      {:ok, token} ->
        case verify_token(token) do
          {:ok, claims} ->
            assign(conn, :current_user, claims)

          {:error, reason} ->
            unauthorized(conn, reason)
        end

      {:error, reason} ->
        unauthorized(conn, reason)
    end
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, "未提供认证token"}
    end
  end

  defp verify_token(token) do
    signer = Joken.Signer.create("HS256", "your-secret-key")

    case Joken.verify(token, signer) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end

  defp unauthorized(conn, reason) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(BaseResponse.generate(401, "认证失败: #{reason}", nil))
    |> halt()
  end
end
