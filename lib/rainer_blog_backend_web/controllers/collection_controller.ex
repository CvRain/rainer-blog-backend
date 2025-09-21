defmodule RainerBlogBackendWeb.CollectionController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.{Collection}
  alias RainerBlogBackendWeb.Types.BaseResponse

  def index(conn, _params) do
    collections = Collection.list_collections()
    render(conn, "index.json", collections: collections)
  end

  def create(conn, params) do
    case Collection.create(params) do
      {:ok, collection} ->
        conn
        |> put_status(:created)
        |> json(BaseResponse.generate(201, "201Created", collection))

      {:error, %Ecto.Changeset{} = changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        json(conn, BaseResponse.generate(400, "400BadRequest", errors))
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
        json(conn, BaseResponse.generate(200, "200Ok", collection))
    end
  end

  def show_all(conn, _params) do
    collections = Collection.list_collections()
    json(conn, BaseResponse.generate(200, "200Ok", collections))
  end

  def show_all_active(conn, _params) do
    collections = Collection.list_active_collections()
    json(conn, BaseResponse.generate(200, "200Ok", collections))
  end

  def update(conn, _params) do
    body_params = conn.body_params
    id = body_params["id"]

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
        case Collection.update_collection(collection, body_params) do
          {:ok, updated_collection} ->
            json(
              conn,
              BaseResponse.generate(200, "Collection updated successfully", updated_collection)
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            errors =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                Enum.reduce(opts, msg, fn {key, value}, acc ->
                  String.replace(acc, "%{#{key}}", to_string(value))
                end)
              end)

            conn
            |> put_status(:bad_request)
            |> json(BaseResponse.generate(400, "400BadRequest", errors))
        end
    end
  end

  def delete(conn, _param) do
    remove_id = conn.body_params["id"]

    case Collection.get_collection(remove_id) do
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
          json(
            conn,
            BaseResponse.generate(200, "Collection and its resources deleted successfully", nil)
          )
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
