defmodule RainerBlogBackendWeb.ArticleController do
  alias RainerBlogBackendWeb.Types.BaseResponse
  use RainerBlogBackendWeb, :controller

  def count(conn, _params) do
    data = %{
      count: RainerBlogBackend.Article.count()
    }
    json(conn, BaseResponse.generate(200, "200Ok", data))
  end

  def count_this_week(conn, _params) do
    data = %{
      count: RainerBlogBackend.Article.count_append_weekly()
    }
    json(conn, BaseResponse.generate(200, "200Ok", data))
  end
end
