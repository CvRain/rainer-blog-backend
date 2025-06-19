defmodule RainerBlogBackendWeb.ResourceController do
  use RainerBlogBackendWeb, :controller

  def index(conn, _params) do
    data = %{
      count: RainerBlogBackend.Resource.count(),
      count_this_week: RainerBlogBackend.Resource.count_this_week()
    }
    json(conn, RainerBlogBackendWeb.Types.BaseResponse.generate(200, "200Ok", data))
  end

  def count(conn, _params) do
    data = %{
      count: RainerBlogBackend.Resource.count(),
    }
    json(conn, RainerBlogBackendWeb.Types.BaseResponse.generate(200, "200Ok", data))

  end

  def count_this_week(conn, _params) do
    data = %{
      count_this_week: RainerBlogBackend.Resource.count_this_week()
    }
    json(conn, RainerBlogBackendWeb.Types.BaseResponse.generate(200, "200Ok", data))
  end
end
