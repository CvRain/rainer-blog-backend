defmodule RainerBlogBackendWeb.ThemeController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.Theme
  alias RainerBlogBackendWeb.Types.BaseResponse

  @spec create(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def create(conn, _params) do
    request_body = conn.body_params
    theme_name = request_body["name"]
    theme_description = request_body["description"]

    cond do
      is_nil(theme_name) or theme_name == "" ->
        json(conn, BaseResponse.generate(400, "400BadRequest", "缺少主题名称"))
      is_nil(theme_description) or theme_description == "" ->
        json(conn, BaseResponse.generate(400, "400BadRequest", "缺少主题描述"))
      true ->
        case Theme.create(theme_name, theme_description) do
          {:ok, theme} ->
            json(conn, BaseResponse.generate(201, "201Created", theme))
          {:error, %Ecto.Changeset{} = changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", to_string(value))
              end)
            end)
            json(conn, BaseResponse.generate(400, "400BadRequest", errors))
          {:error, err} ->
            json(conn, BaseResponse.generate(400, "400BadRequest", err))
        end
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
          {:ok, theme} ->
            json(conn, BaseResponse.generate(200, "200OK", theme))
          {:error, %Ecto.Changeset{} = changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", to_string(value))
              end)
            end)
            json(conn, BaseResponse.generate(400, "400BadRequest", errors))
          {:error, err} when is_binary(err) ->
            json(conn, BaseResponse.generate(400, "400BadRequest", err))
          {:error, _} ->
            json(conn, BaseResponse.generate(500, "500Internal Server Error", "更新失败"))
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
      # 构建配置映射，正确处理数据类型
      config = %{
        id: params["id"],
        name: params["name"],
        description: params["description"] || "",
        order: parse_integer(params["order"], 0),
        is_active: parse_boolean(params["is_active"], false)
      }

      {:ok, config}
    else
      {:error, "缺少必填字段: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  defp parse_integer(value, default) when is_integer(value), do: value
  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end
  defp parse_integer(_, default), do: default

  defp parse_boolean(value, default) when is_boolean(value), do: value
  defp parse_boolean(value, default) when is_binary(value) do
    case String.downcase(value) do
      "true" -> true
      "false" -> false
      _ -> default
    end
  end
  defp parse_boolean(_, default), do: default

  def all_themes_with_stats(conn, _params) do
    themes = Theme.get_all_with_stats()
    json(conn, BaseResponse.generate(200, "200OK", themes))
  end
end
