defmodule RainerBlogBackendWeb.ChapterController do
  use RainerBlogBackendWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackend.Chapter
  alias RainerBlogBackendWeb.Schemas.BaseResponse, as: BaseResponseSchema

  alias RainerBlogBackendWeb.Schemas.{
    ChapterResponse,
    ChapterListResponse,
    ChapterParams,
    ChapterUpdateParams
  }

  tags(["chapters"])

  operation(:create,
    summary: "Create chapter",
    description: "Create a new chapter.",
    request_body: {"Chapter params", "application/json", ChapterParams},
    responses: [
      created: {"Chapter", "application/json", ChapterResponse},
      bad_request: {"Bad Request", "application/json", BaseResponseSchema}
    ]
  )

  def create(conn, params) do
    case Chapter.create(params) do
      {:ok, chapter} ->
        json(conn, BaseResponse.generate(201, "201Created", chapter))

      {:error, changeset} ->
        IO.puts("create chapter error")
        IO.puts(changeset)

        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        json(conn, BaseResponse.generate(400, "400BadRequest", errors))
    end
  end

  operation(:index,
    summary: "List chapters",
    description: "Get all chapters with pagination.",
    parameters: [
      page: [
        in: :query,
        description: "Page number",
        schema: %OpenApiSpex.Schema{type: :integer, default: 1}
      ],
      page_size: [
        in: :query,
        description: "Page size",
        schema: %OpenApiSpex.Schema{type: :integer, default: 10}
      ]
    ],
    responses: [
      ok: {"Chapter list", "application/json", ChapterListResponse}
    ]
  )

  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_all(page, page_size)
    json(conn, BaseResponse.generate(200, "200OK", chapters))
  end

  operation(:active,
    summary: "List active chapters",
    description: "Get active chapters with pagination.",
    parameters: [
      page: [
        in: :query,
        description: "Page number",
        schema: %OpenApiSpex.Schema{type: :integer, default: 1}
      ],
      page_size: [
        in: :query,
        description: "Page size",
        schema: %OpenApiSpex.Schema{type: :integer, default: 10}
      ]
    ],
    responses: [
      ok: {"Chapter list", "application/json", ChapterListResponse}
    ]
  )

  def active(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_active(page, page_size)
    json(conn, BaseResponse.generate(200, "200OK", chapters))
  end

  operation(:by_theme,
    summary: "List chapters by theme",
    description: "Get chapters by theme with pagination.",
    parameters: [
      theme_id: [
        in: :path,
        description: "Theme ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ],
      page: [
        in: :query,
        description: "Page number",
        schema: %OpenApiSpex.Schema{type: :integer, default: 1}
      ],
      page_size: [
        in: :query,
        description: "Page size",
        schema: %OpenApiSpex.Schema{type: :integer, default: 10}
      ]
    ],
    responses: [
      ok: {"Chapter list", "application/json", ChapterListResponse}
    ]
  )

  def by_theme(conn, %{"theme_id" => theme_id} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_by_theme(theme_id, page, page_size)
    json(conn, BaseResponse.generate(200, "200OK", chapters))
  end

  operation(:active_by_theme,
    summary: "List active chapters by theme",
    description: "Get active chapters by theme with pagination.",
    parameters: [
      theme_id: [
        in: :path,
        description: "Theme ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ],
      page: [
        in: :query,
        description: "Page number",
        schema: %OpenApiSpex.Schema{type: :integer, default: 1}
      ],
      page_size: [
        in: :query,
        description: "Page size",
        schema: %OpenApiSpex.Schema{type: :integer, default: 10}
      ]
    ],
    responses: [
      ok: {"Chapter list", "application/json", ChapterListResponse}
    ]
  )

  def active_by_theme(conn, %{"theme_id" => theme_id} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_active_by_theme(theme_id, page, page_size)
    json(conn, BaseResponse.generate(200, "200OK", chapters))
  end

  operation(:delete,
    summary: "Delete chapter",
    description: "Delete a chapter by ID.",
    parameters: [
      id: [
        in: :path,
        description: "Chapter ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Deleted", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def delete(conn, %{"id" => id}) do
    case Chapter.delete(id) do
      {:ok, _chapter} ->
        json(conn, BaseResponse.generate(204, "204NoContent", nil))

      {:error, _changeset} ->
        json(conn, BaseResponse.generate(404, "404NotFound", "Chapter not found"))
    end
  end

  operation(:update,
    summary: "Update chapter",
    description: "Update a chapter.",
    request_body: {"Update params", "application/json", ChapterUpdateParams},
    responses: [
      ok: {"Chapter", "application/json", ChapterResponse},
      bad_request: {"Bad Request", "application/json", BaseResponseSchema}
    ]
  )

  def update(conn, _params) do
    request_body = conn.body_params
    id = request_body["id"]
    update_params = Map.delete(request_body, "id")

    if is_nil(id) or id == "" do
      json(conn, BaseResponse.generate(400, "缺少必要参数id", nil))
    else
      case Chapter.update(id, update_params) do
        {:ok, chapter} ->
          json(conn, BaseResponse.generate(200, "200OK", chapter))

        {:error, changeset} ->
          errors =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", to_string(value))
              end)
            end)

          json(conn, BaseResponse.generate(422, "422UnprocessableEntity", errors))
      end
    end
  end
end
