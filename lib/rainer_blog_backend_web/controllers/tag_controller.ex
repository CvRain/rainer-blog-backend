defmodule RainerBlogBackendWeb.TagController do
  use RainerBlogBackendWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias RainerBlogBackend.{Tag, Article}
  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackendWeb.Schemas.{TagResponse, TagDetailResponse}
  alias RainerBlogBackendWeb.Schemas.BaseResponse, as: BaseResponseSchema

  tags(["tags"])

  operation(:index,
    summary: "List all tags",
    description: "Get a list of all tags available in the blog.",
    responses: [
      ok: {"Tag list", "application/json", TagResponse}
    ]
  )

  def index(conn, _params) do
    tags = RainerBlogBackend.Repo.all(Tag)
    json(conn, BaseResponse.generate(200, "200OK", tags))
  end

  operation(:show,
    summary: "Get tag details and articles",
    description: "Get detials of a specific tag and the list of articles associated with it.",
    parameters: [
      name: [
        in: :path,
        description: "Tag name",
        schema: %OpenApiSpex.Schema{type: :string, example: "Elixir"}
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
      ok: {"Tag details and articles", "application/json", TagDetailResponse},
      not_found: {"Tag not found", "application/json", BaseResponseSchema}
    ]
  )

  def show(conn, %{"name" => name} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    case RainerBlogBackend.Repo.get_by(Tag, name: name) do
      nil ->
        json(conn, BaseResponse.generate(404, "Tag not found", nil))

      tag ->
        articles = Article.list_public_articles_by_tag(name, page, page_size)

        data = %{
          tag: tag,
          articles: articles
        }

        json(conn, BaseResponse.generate(200, "200OK", data))
    end
  end
end
