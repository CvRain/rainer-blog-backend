defmodule RainerBlogBackendWeb.OtherPageController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackendWeb.Types.BaseResponse

  def main(conn, _params) do
    data = %{
      timestamp: :os.system_time(:millisecond),
      method: conn.method,
      host: conn.host,
      port: conn.port
    }
    response = BaseResponse.generate(200, "Hello world!", data)

    IO.puts(inspect(conn))

    json(conn, response)
  end


  def storage_overview(conn, _params) do
    data = %{
      article_count: RainerBlogBackend.Article.count(),
      article_append_weekly: RainerBlogBackend.Article.count_append_weekly(),
      theme_count: RainerBlogBackend.Theme.count(),
      theme_append_weekly: RainerBlogBackend.Theme.count_append_weekly,
      collection_count: RainerBlogBackend.Collection.count(),
      collection_append_weekly: RainerBlogBackend.Collection.count_append_weekly(),
      resource_count: RainerBlogBackend.Resource.count(),
      resource_append_weekly: RainerBlogBackend.Resource.count_append_weekly(),
    }
    response = BaseResponse.generate(200, "200 Ok", data)

    json(conn, response)
  end
end
