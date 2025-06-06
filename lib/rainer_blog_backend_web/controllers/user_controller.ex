defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackendWeb.Types.BaseResponse

  @doc """
    检查配置文件中，用户数据是否存在
  """
  def check_user(conn, _params) do
    user = Application.get_env(:rainer_blog_backend, :user)
    if user do
      conn
      |> BaseResponse.generate(200, "success", "user is exists")
    else
      conn
      |> BaseResponse.generate(404, "not found", "user is not exists")
    end
  end

  def show(conn, _params) do
    user = Application.get_env(:rainer_blog_backend, :user)
    conn
    |> BaseResponse.generate(200, "success", user)
  end


end
