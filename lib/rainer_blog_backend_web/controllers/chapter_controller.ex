defmodule RainerBlogBackendWeb.ChapterController do
  use RainerBlogBackendWeb, :controller
  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackend.Chapter

  @doc """
  创建一个新的Chapter
  """
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

  @doc """
  获取所有Chapter，支持分页
  """
  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_all(page, page_size)
    json(conn, BaseResponse.generate(200, "200OK", chapters))
  end

  @doc """
  获取所有激活的Chapter，支持分页
  """
  def active(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_active(page, page_size)
    json(conn, BaseResponse.generate(200, "200OK", chapters))
  end

  @doc """
  获取指定theme下的所有Chapter
  """
  def by_theme(conn, %{"theme_id" => theme_id} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_by_theme(theme_id, page, page_size)
    json(conn, BaseResponse.generate(200, "200OK", chapters))
  end

  @doc """
  获取指定theme下激活的Chapter
  """
  def active_by_theme(conn, %{"theme_id" => theme_id} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    chapters = Chapter.get_active_by_theme(theme_id, page, page_size)
    json(conn, BaseResponse.generate(200, "200OK", chapters))
  end

  @doc """
  删除指定的Chapter
  """
  def delete(conn, %{"id" => id}) do
    case Chapter.delete(id) do
      {:ok, _chapter} ->
        json(conn, BaseResponse.generate(204, "204NoContent", nil))

      {:error, _changeset} ->
        json(conn, BaseResponse.generate(404, "404NotFound", "Chapter not found"))
    end
  end

  @doc """
  更新指定的Chapter
  """
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
