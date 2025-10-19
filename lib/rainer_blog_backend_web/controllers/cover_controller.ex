defmodule RainerBlogBackendWeb.CoverController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.{Cover, Resource, AwsService}
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

  # GET /api/cover/articles?page=1&page_size=10
  def articles(conn, params) do
    page = (params["page"] || 1) |> to_int()
    page_size = (params["page_size"] || 10) |> to_int()

    data = Cover.list_article_covers(page, page_size)
    json(conn, BaseResponse.generate(200, "ok", data))
  end

  # GET /api/cover/article/:id
  def article(conn, %{"id" => id}) do
    case Cover.get_cover_info("article", id) do
      {:ok, info} -> json(conn, BaseResponse.generate(200, "ok", info))
      {:error, :not_found} -> json(conn, BaseResponse.generate(404, "cover not found", nil))
      {:error, :resource_not_found} -> json(conn, BaseResponse.generate(404, "resource not found", nil))
      {:error, reason} -> json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # GET /api/cover/theme/:id
  def theme(conn, %{"id" => id}) do
    case Cover.get_cover_info("theme", id) do
      {:ok, info} -> json(conn, BaseResponse.generate(200, "ok", info))
      {:error, :not_found} -> json(conn, BaseResponse.generate(404, "cover not found", nil))
      {:error, :resource_not_found} -> json(conn, BaseResponse.generate(404, "resource not found", nil))
      {:error, reason} -> json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # GET /api/cover/chapter/:id
  def chapter(conn, %{"id" => id}) do
    case Cover.get_cover_info("chapter", id) do
      {:ok, info} -> json(conn, BaseResponse.generate(200, "ok", info))
      {:error, :not_found} -> json(conn, BaseResponse.generate(404, "cover not found", nil))
      {:error, :resource_not_found} -> json(conn, BaseResponse.generate(404, "resource not found", nil))
      {:error, reason} -> json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # GET /api/cover/theme/:id/chapters
  def theme_chapters(conn, %{"id" => id}) do
    data = Cover.get_chapter_covers_by_theme(id)
    json(conn, BaseResponse.generate(200, "ok", data))
  end

  # GET /api/cover/chapter/:id/articles
  def chapter_articles(conn, %{"id" => id}) do
    data = Cover.get_article_covers_by_chapter(id)
    json(conn, BaseResponse.generate(200, "ok", data))
  end

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1

  # POST /api/cover/upload_set
  # multipart form-data: file + owner_type + owner_id
  def upload_set(conn, %{"file" => file_param, "owner_type" => owner_type, "owner_id" => owner_id} = params) do
    filename = file_param.filename
    content = file_param.path |> File.read!()
    file_size = byte_size(content)
    file_type = params["file_type"] || get_file_type(filename)

    # generate aws_key
    uuid = Ecto.UUID.generate()
    ext = filename |> Path.extname() |> String.downcase()
    aws_key = "resources/#{uuid}#{ext}"

    case AwsService.upload_content(content, aws_key) do
      {:ok, _s3_path} ->
        attrs = %{
          name: params["name"] || filename,
          description: params["description"] || filename,
          file_type: file_type,
          file_size: file_size,
          aws_key: aws_key,
          order: params["order"] || 0,
          is_active: params["is_active"] || true,
          collection_id: params["collection_id"]
        }

        case Resource.create_resource(attrs) do
          {:ok, resource} ->
            case Cover.set_cover(owner_type, owner_id, resource.id) do
              {:ok, cover} ->
                json(conn, BaseResponse.generate(201, "cover set successfully", %{cover: cover, resource: resource}))

              {:error, changeset} ->
                errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                  Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
                end)

                json(conn, BaseResponse.generate(400, "failed to set cover", errors))
            end

          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
            end)

            json(conn, BaseResponse.generate(400, "invalid resource params", errors))
        end

      {:error, reason} ->
        json(conn, BaseResponse.generate(500, "S3 upload failed", %{error: inspect(reason)}))
    end
  end

  defp get_file_type(filename) do
    ext = filename |> Path.extname() |> String.downcase()

    case ext do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      _ -> "application/octet-stream"
    end
  end
end
