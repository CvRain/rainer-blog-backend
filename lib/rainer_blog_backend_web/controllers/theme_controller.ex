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

  def all_themes_with_details(conn, _params) do
    themes = Theme.get_all_with_details()
    json(conn, BaseResponse.generate(200, "200OK", themes))
  end

  def one_theme_with_details(conn, %{"id" => id}) do
    theme = RainerBlogBackend.Theme.get_one(id)
    if is_nil(theme) do
      json(conn, BaseResponse.generate(404, "404NotFound", "主题不存在"))
    else
      chapters = RainerBlogBackend.Chapter.get_by_theme(theme.id, 1, 1000)
      chapters_with_articles = Enum.map(chapters, fn chapter ->
        articles = RainerBlogBackend.Article.get_by_chapter(chapter.id)
        chapter_map = Map.from_struct(chapter) |> Map.drop([:__meta__, :__struct__])
        Map.put(chapter_map, :articles, articles)
      end)
      theme_map = Map.from_struct(theme) |> Map.drop([:__meta__, :__struct__])
      data = Map.put(theme_map, :chapters, chapters_with_articles)
      json(conn, BaseResponse.generate(200, "200OK", data))
    end
  end
end
