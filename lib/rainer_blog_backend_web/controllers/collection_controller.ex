defmodule RainerBlogBackendWeb.CollectionController do
  use RainerBlogBackendWeb, :controller

  def create(conn, _params) do
    json(conn, %{message: "Hello, World!"})
  end

  def remove(conn, _params) do
    json(conn, %{message: "Hello, World!"})
  end

  def update(conn, _params) do
    json(conn, %{message: "Hello, World!"})
  end

  def list(conn, _params) do
    json(conn, %{message: "Hello, World!"})
  end
end
