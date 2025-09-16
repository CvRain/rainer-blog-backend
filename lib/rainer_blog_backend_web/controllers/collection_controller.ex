defmodule RainerBlogBackendWeb.CollectionController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.{Collection, Resource}
  alias RainerBlogBackendWeb.Types.BaseResponse

  action_fallback RainerBlogBackendWeb.ErrorJSON

  def index(conn, _params) do
    collections = Collection.list_collections()
    render(conn, "index.json", collections: collections)
  end

  def create(conn, %{"collection" => collection_params}) do
    with {:ok, %Collection{} = collection} <- Collection.create(collection_params) do
      conn
      |> put_status(:created)
      |> render("show.json", collection: collection)
    end
  end

  def show(conn, %{"id" => id}) do
    case Collection.get_collection(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%BaseResponse{
          code: 404,
          message: "Collection not found",
          data: nil
        })

      collection ->
        render(conn, "show.json", collection: collection)
    end
  end

  def update(conn, %{"id" => id, "collection" => collection_params}) do
    case Collection.get_collection(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%BaseResponse{
          code: 404,
          message: "Collection not found",
          data: nil
        })

      collection ->
        with {:ok, %Collection{} = collection} <- Collection.update_collection(collection, collection_params) do
          render(conn, "show.json", collection: collection)
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Collection.get_collection(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%BaseResponse{
          code: 404,
          message: "Collection not found",
          data: nil
        })

      collection ->
        with {:ok, %Collection{}} <- Collection.delete_collection(collection) do
          send_resp(conn, :no_content, "")
        end
    end
  end

  @doc """
    获取资源总数
  """
  def count(conn, _params) do
    data = %{
      count: Collection.count()
    }
    json(conn, BaseResponse.generate(200, "200Ok", data))
  end

  @doc """
    获取本周新增资源数
  """
  def count_append_weekly(conn, _params) do
    data = %{
      count: Collection.count_append_weekly()
    }
    json(conn, BaseResponse.generate(200, "200Ok", data))
  end
end