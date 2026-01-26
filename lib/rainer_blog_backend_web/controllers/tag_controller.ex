defmodule RainerBlogBackendWeb.TagController do
  use RainerBlogBackendWeb, :controller
  alias RainerBlogBackend.{Tag, Article}
  alias RainerBlogBackendWeb.Types.BaseResponse

  def index(conn, _params) do
    tags = RainerBlogBackend.Repo.all(Tag)
    json(conn, BaseResponse.generate(200, "200OK", tags))
  end

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
