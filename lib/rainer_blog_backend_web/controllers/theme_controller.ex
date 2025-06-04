defmodule RainerBlogBackendWeb.ThemeController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.Theme
  alias RainerBlogBackendWeb.Types.BaseResponse

  @doc """
  获取主题列表，支持分页
  """
  def index(conn, params) do
    page = (params["page"] || "1") |> String.to_integer()
    page_size = (params["page_size"] || "10") |> String.to_integer()

    themes = Theme.list_themes(page, page_size)
    total = Theme.count_themes()

    response = BaseResponse.generate(200, "success", %{
      themes: themes,
      pagination: %{
        page: page,
        page_size: page_size,
        total: total,
        total_pages: ceil(total / page_size)
      }
    })

    conn
    |> put_status(response.code)
    |> json(response)
  end

  @doc """
  获取单个主题
  """
  def show(conn, %{"id" => id}) do
    case Theme.get_theme(id) do
      nil ->
        response = BaseResponse.generate(404, "Theme not found", nil)
        conn
        |> put_status(response.code)
        |> json(response)

      theme ->
        response = BaseResponse.generate(200, "success", theme)
        conn
        |> put_status(response.code)
        |> json(response)
    end
  end

  @doc """
  创建主题
  """
  def create(conn, params) do
    case Theme.create_theme(params) do
      {:ok, theme} ->
        response = BaseResponse.generate(201, "success", theme)
        conn
        |> put_status(response.code)
        |> json(response)

      {:error, changeset} ->
        response = BaseResponse.generate(422, "validation error", changeset_errors(changeset))
        conn
        |> put_status(response.code)
        |> json(response)
    end
  end

  @doc """
  删除主题
  """
  def delete(conn, %{"id" => id}) do
    case Theme.delete_theme(id) do
      {:ok, _theme} ->
        response = BaseResponse.generate(204, "success", nil)
        conn
        |> put_status(response.code)
        |> json(response)

      {:error, :not_found} ->
        response = BaseResponse.generate(404, "Theme not found", nil)
        conn
        |> put_status(response.code)
        |> json(response)

      {:error, _changeset} ->
        response = BaseResponse.generate(500, "failed to delete theme", nil)
        conn
        |> put_status(response.code)
        |> json(response)
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
