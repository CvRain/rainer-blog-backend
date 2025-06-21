defmodule RainerBlogBackendWeb.ThemeController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.Theme
  alias RainerBlogBackendWeb.Types.BaseResponse

  @spec create(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def create(conn, _params) do
    request_body = conn.body_params
    theme_name = request_body["name"]
    theme_description = request_body["description"]

    with true <- Map.has_key?(request_body, "name"),
         true <- Map.has_key?(request_body, "description") do
      case Theme.create(theme_name, theme_description) do
        {:ok, theme} -> json(conn, BaseResponse.generate(201, "201Created", theme))
        {:error, err} -> json(conn, BaseResponse.generate(400, "400BadRequest", err))
      end
    else
      _ -> json(conn, BaseResponse.generate(400, "400BadRequest", "参数错误"))
    end
  end

  def all_themes(conn, _params) do
    themes = Theme.get_all()
    json(conn, BaseResponse.generate(200, "200OK", themes))
  end

  def activite_themes(conn, _params) do
    themes =
      Theme.get_all()
      |> Enum.filter(fn theme -> theme.is_active end)

    json(conn, BaseResponse.generate(200, "200OK", themes))
  end

  def one_theme(conn, %{"id" => id}) do
    theme = Theme.get_one(id)
    json(conn, BaseResponse.generate(200, "200OK", theme))
  end

  def remove(conn, _params) do
    remove_id = conn.body_params["id"]

    case Theme.remove(remove_id) do
      {:ok, _} ->
        json(conn, BaseResponse.generate(200, "200OK", nil))

      {:error, _} ->
        json(conn, BaseResponse.generate(500, "500Internal Server Error", nil))
    end
  end

  def count(conn, _params) do
    count = Theme.count()
    response = %{
      count: count
    }
    json(conn, BaseResponse.generate(200, "200OK", response))
  end

  def count_this_week(conn, _params) do
    count = Theme.count_append_weekly()
    response = %{
      count: count
    }
    json(conn, BaseResponse.generate(200, "200OK", response))
  end

  def update(conn, _params) do
    request_body = conn.body_params
    case validate_theme_config(request_body) do
      {:ok, config} ->
        case Theme.update(config) do
          {:ok, _} ->
            json(conn, BaseResponse.generate(200, "200OK", nil))

          {:error, _} ->
            json(conn, BaseResponse.generate(500, "500Internal Server Error", nil))
        end

      {:error, err} ->
        json(conn, BaseResponse.generate(400, "400BadRequest", err))
    end
  end

  defp validate_theme_config(params) do
    required_fields = ["id"]
    optional_fields = ["name", "description", "order", "is_active"]

    missing_fields = Enum.filter(required_fields, &(is_nil(params[&1]) or params[&1] == ""))

    if Enum.empty?(missing_fields) do
      # 构建配置映射
      config =
        Map.new(required_fields ++ optional_fields, fn field ->
          {String.to_atom(field), params[field] || ""}
        end)

      {:ok, config}
    else
      {:error, "缺少必填字段: #{Enum.join(missing_fields, ", ")}"}
    end
  end
end
