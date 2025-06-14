defmodule RainerBlogBackendWeb.ChapterController do
  use RainerBlogBackendWeb, :controller
  alias RainerBlogBackend.Chapter

  @doc """
  创建一个新的Chapter
  """
  def create(conn, params) do
    case Chapter.create(params) do
      {:ok, chapter} ->
        conn
        |> put_status(:created)
        |> json(chapter)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_errors(changeset)})
    end
  end

  @doc """
  获取所有Chapter，支持分页
  """
  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_all(page, page_size)
    json(conn, chapters)
  end

  @doc """
  获取所有激活的Chapter，支持分页
  """
  def active(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_active(page, page_size)
    json(conn, chapters)
  end

  @doc """
  获取指定theme下的所有Chapter
  """
  def by_theme(conn, %{"theme_id" => theme_id} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_by_theme(theme_id, page, page_size)
    json(conn, chapters)
  end

  @doc """
  获取指定theme下激活的Chapter
  """
  def active_by_theme(conn, %{"theme_id" => theme_id} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_active_by_theme(theme_id, page, page_size)
    json(conn, chapters)
  end

  @doc """
  删除指定的Chapter
  """
  def delete(conn, %{"id" => id}) do
    case Chapter.delete(id) do
      {:ok, _chapter} ->
        conn
        |> put_status(:no_content)
        |> json(%{})

      {:error, _changeset} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Chapter not found"})
    end
  end

  @doc """
  更新指定的Chapter
  """
  def update(conn, %{"id" => id} = params) do
    case Chapter.update(id, params) do
      {:ok, chapter} ->
        json(conn, chapter)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_errors(changeset)})
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
