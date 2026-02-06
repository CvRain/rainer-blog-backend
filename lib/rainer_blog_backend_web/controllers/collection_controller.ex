defmodule RainerBlogBackendWeb.CollectionController do
  use RainerBlogBackendWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias RainerBlogBackend.{Collection}
  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackendWeb.Schemas.BaseResponse, as: BaseResponseSchema

  alias RainerBlogBackendWeb.Schemas.{
    CollectionResponse,
    CollectionListResponse,
    CollectionParams,
    CollectionUpdateParams,
    CountResponse
  }

  tags(["collections"])

  operation(:index,
    summary: "List collections (legacy)",
    description: "List collections (legacy response).",
    responses: [
      ok: {"Collection list", "application/json", CollectionListResponse}
    ]
  )

  def index(conn, _params) do
    collections = Collection.list_collections()
    render(conn, "index.json", collections: collections)
  end

  operation(:create,
    summary: "Create collection",
    description: "Create a new collection.",
    request_body: {"Collection params", "application/json", CollectionParams},
    responses: [
      created: {"Collection", "application/json", CollectionResponse},
      bad_request: {"Bad Request", "application/json", BaseResponseSchema}
    ]
  )

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

  operation(:show,
    summary: "Get collection",
    description: "Get a collection by ID.",
    parameters: [
      id: [
        in: :path,
        description: "Collection ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Collection", "application/json", CollectionResponse},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

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

  operation(:show_all,
    summary: "List all collections",
    description: "Get all collections.",
    responses: [
      ok: {"Collection list", "application/json", CollectionListResponse}
    ]
  )

  def show_all(conn, _params) do
    collections = Collection.list_collections()
    json(conn, BaseResponse.generate(200, "200Ok", collections))
  end

  operation(:show_all_active,
    summary: "List active collections",
    description: "Get all active collections.",
    responses: [
      ok: {"Collection list", "application/json", CollectionListResponse}
    ]
  )

  def show_all_active(conn, _params) do
    collections = Collection.list_active_collections()
    json(conn, BaseResponse.generate(200, "200Ok", collections))
  end

  operation(:update,
    summary: "Update collection",
    description: "Update a collection.",
    request_body: {"Update params", "application/json", CollectionUpdateParams},
    responses: [
      ok: {"Collection", "application/json", CollectionResponse},
      bad_request: {"Bad Request", "application/json", BaseResponseSchema}
    ]
  )

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

  operation(:delete,
    summary: "Delete collection",
    description: "Delete a collection by ID.",
    request_body: {"Delete params", "application/json", CollectionUpdateParams},
    responses: [
      ok: {"Deleted", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

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
  operation(:count,
    summary: "Get collection count",
    description: "Get total number of collections.",
    responses: [
      ok: {"Count", "application/json", CountResponse}
    ]
  )

  def count(conn, _params) do
    data = %{
      count: Collection.count()
    }

    json(conn, BaseResponse.generate(200, "200Ok", data))
  end

  @doc """
    获取本周新增资源数
  """
  operation(:count_append_weekly,
    summary: "Get weekly collection count",
    description: "Get number of collections created this week.",
    responses: [
      ok: {"Count", "application/json", CountResponse}
    ]
  )

  def count_append_weekly(conn, _params) do
    data = %{
      count: Collection.count_append_weekly()
    }

    json(conn, BaseResponse.generate(200, "200Ok", data))
  end
end
