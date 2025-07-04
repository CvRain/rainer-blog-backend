defmodule RainerBlogBackendWeb.S3Controller do
  use RainerBlogBackendWeb, :controller
  alias RainerBlogBackend.UserConfig

  # 内网 IP 校验
  defp internal_ip?(conn) do
    ip = Tuple.to_list(conn.remote_ip) |> Enum.join(".")
    String.starts_with?(ip, ["10.", "192.168.", "127."]) or
      (String.starts_with?(ip, "172.") and
        (case String.split(ip, ".") do
          [_, second, _, _] ->
            case Integer.parse(second) do
              {n, _} when n >= 16 and n <= 31 -> true
              _ -> false
            end
          _ -> false
        end))
  end

  def update_config(conn, params) do
    if internal_ip?(conn) do
      required = ["access_key_id", "secret_access_key", "region", "bucket"]
      if Enum.all?(required, &Map.has_key?(params, &1)) do
        config = %{
          access_key_id: params["access_key_id"],
          secret_access_key: params["secret_access_key"],
          region: params["region"],
          bucket: params["bucket"]
        }
        :ok = UserConfig.update_aws_config(config)
        json(conn, %{code: 0, msg: "ok", data: config})
      else
        json(conn, %{code: 1, msg: "参数不完整", data: nil})
      end
    else
      conn
      |> put_status(403)
      |> json(%{code: 403, msg: "forbidden", data: nil})
    end
  end

  def get_config(conn, _params) do
    if internal_ip?(conn) do
      config = UserConfig.get_aws_config()
      json(conn, %{code: 0, msg: "ok", data: config})
    else
      conn
      |> put_status(403)
      |> json(%{code: 403, msg: "forbidden", data: nil})
    end
  end
end
