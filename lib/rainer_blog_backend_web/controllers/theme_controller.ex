defmodule RainerBlogBackendWeb.ThemeController do
  use RainerBlogBackendWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias RainerBlogBackend.Theme
  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackendWeb.Schemas.BaseResponse, as: BaseResponseSchema

  alias RainerBlogBackendWeb.Schemas.{
    ThemeResponse,
    ThemeListResponse,
    ThemeParams,
    ThemeUpdateParams,
    CountResponse
  }

  tags(["themes"])

  operation(:create,
    summary: "Create theme",
    description: "Create a new theme.",
    request_body: {"Theme params", "application/json", ThemeParams},
    responses: [
      created: {"Theme", "application/json", ThemeResponse},
      bad_request: {"Bad Request", "application/json", BaseResponseSchema}
    ]
  )

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
            errors =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
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

  operation(:all_themes,
    summary: "List themes",
    description: "Get all themes.",
    responses: [
      ok: {"Theme list", "application/json", ThemeListResponse}
    ]
  )

  def all_themes(conn, _params) do
    themes = Theme.get_all()
    json(conn, BaseResponse.generate(200, "200OK", themes))
  end

  operation(:active_themes,
    summary: "List active themes",
    description: "Get all active themes.",
    responses: [
      ok: {"Theme list", "application/json", ThemeListResponse}
    ]
  )

  def active_themes(conn, _params) do
    themes =
      Theme.get_all()
      |> Enum.filter(fn theme -> theme.is_active end)

    json(conn, BaseResponse.generate(200, "200OK", themes))
  end

  operation(:one_theme,
    summary: "Get theme",
    description: "Get a theme by ID.",
    parameters: [
      id: [
        in: :path,
        description: "Theme ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Theme", "application/json", ThemeResponse}
    ]
  )

  def one_theme(conn, %{"id" => id}) do
    theme = Theme.get_one(id)
    json(conn, BaseResponse.generate(200, "200OK", theme))
  end

  operation(:remove,
    summary: "Remove theme",
    description: "Remove a theme by ID.",
    request_body: {"Remove params", "application/json", ThemeUpdateParams},
    responses: [
      ok: {"Removed", "application/json", BaseResponseSchema}
    ]
  )

  def remove(conn, _params) do
    remove_id = conn.body_params["id"]

    case Theme.remove(remove_id) do
      {:ok, _} ->
        json(conn, BaseResponse.generate(200, "200OK", nil))

      {:error, _} ->
        json(conn, BaseResponse.generate(500, "500Internal Server Error", nil))
    end
  end

  operation(:count,
    summary: "Get theme count",
    description: "Get total number of themes.",
    responses: [
      ok: {"Count", "application/json", CountResponse}
    ]
  )

  def count(conn, _params) do
    count = Theme.count()

    response = %{
      count: count
    }

    json(conn, BaseResponse.generate(200, "200OK", response))
  end

  operation(:count_this_week,
    summary: "Get weekly theme count",
    description: "Get number of themes created this week.",
    responses: [
      ok: {"Count", "application/json", CountResponse}
    ]
  )

  def count_this_week(conn, _params) do
    count = Theme.count_append_weekly()

    response = %{
      count: count
    }

    json(conn, BaseResponse.generate(200, "200OK", response))
  end

  operation(:update,
    summary: "Update theme",
    description: "Update a theme.",
    request_body: {"Update params", "application/json", ThemeUpdateParams},
    responses: [
      ok: {"Theme", "application/json", ThemeResponse},
      bad_request: {"Bad Request", "application/json", BaseResponseSchema}
    ]
  )

  def update(conn, _params) do
    request_body = conn.body_params

    case validate_theme_config(request_body) do
      {:ok, config} ->
        case Theme.update(config) do
          {:ok, theme} ->
            json(conn, BaseResponse.generate(200, "200OK", theme))

          {:error, %Ecto.Changeset{} = changeset} ->
            errors =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
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

  defp parse_integer(value, _default) when is_integer(value), do: value

  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_integer(_, default), do: default

  defp parse_boolean(value, _default) when is_boolean(value), do: value

  defp parse_boolean(value, default) when is_binary(value) do
    case String.downcase(value) do
      "true" -> true
      "false" -> false
      _ -> default
    end
  end

  defp parse_boolean(_, default), do: default

  operation(:all_themes_with_stats,
    summary: "List themes with stats",
    description: "Get all themes with statistics.",
    responses: [
      ok: {"Theme list", "application/json", BaseResponseSchema}
    ]
  )

  def all_themes_with_stats(conn, _params) do
    themes = Theme.get_all_with_stats()
    json(conn, BaseResponse.generate(200, "200OK", themes))
  end

  operation(:all_themes_with_details,
    summary: "List themes with details",
    description: "Get all themes with details.",
    responses: [
      ok: {"Theme list", "application/json", BaseResponseSchema}
    ]
  )

  def all_themes_with_details(conn, _params) do
    themes = Theme.get_all_with_details()
    json(conn, BaseResponse.generate(200, "200OK", themes))
  end

  operation(:one_theme_with_details,
    summary: "Get theme details",
    description: "Get theme details by ID.",
    parameters: [
      id: [
        in: :path,
        description: "Theme ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Theme details", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def one_theme_with_details(conn, %{"id" => id}) do
    case Theme.get_active_details(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "主题不存在或未激活"))

      theme_details ->
        json(conn, BaseResponse.generate(200, "200OK", theme_details))
    end
  end

  operation(:public_active_details,
    summary: "Get active theme details (public)",
    description: "Get active theme details by ID (public).",
    parameters: [
      id: [
        in: :path,
        description: "Theme ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Theme details", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def public_active_details(conn, %{"id" => id}) do
    case Theme.get_active_details(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "未找到激活主题或主题未激活", nil))

      theme_map ->
        json(conn, BaseResponse.generate(200, "OK", theme_map))
    end
  end
end
