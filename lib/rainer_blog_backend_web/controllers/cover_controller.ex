defmodule RainerBlogBackendWeb.CoverController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.{Cover, Resource}
  alias RainerBlogBackendWeb.Types.BaseResponse

  # POST /api/cover/set
  # body: {"owner_type": "theme|chapter|article", "owner_id": "uuid", "resource_id": "uuid"}
  def set(conn, %{"owner_type" => owner_type, "owner_id" => owner_id, "resource_id" => resource_id}) do
    case Resource.get_resource(resource_id) do
      nil -> json(conn, BaseResponse.generate(404, "resource not found", nil))

      _resource ->
        case Cover.set_cover(owner_type, owner_id, resource_id) do
          {:ok, cover} -> json(conn, BaseResponse.generate(200, "set cover ok", cover))
          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
            end)

            json(conn, BaseResponse.generate(400, "invalid params", errors))
        end
    end
  end

  # GET /api/cover/url?owner_type=theme&owner_id=...
  def url(conn, %{"owner_type" => owner_type, "owner_id" => owner_id}) do
    case Cover.get_presigned_url_by_owner(owner_type, owner_id) do
      {:ok, url} -> json(conn, BaseResponse.generate(200, "ok", %{url: url}))
      {:error, :not_found} -> json(conn, BaseResponse.generate(404, "cover not found", nil))
      {:error, :resource_not_found} -> json(conn, BaseResponse.generate(404, "resource not found", nil))
      {:error, reason} -> json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # DELETE /api/cover?owner_type=theme&owner_id=...
  def delete(conn, %{"owner_type" => owner_type, "owner_id" => owner_id}) do
    case Cover.delete_by_owner(owner_type, owner_id) do
      {:ok, _} -> json(conn, BaseResponse.generate(200, "deleted", nil))
      {:error, reason} -> json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end
end
