defmodule RainerBlogBackendWeb.CoverController do
  use RainerBlogBackendWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias RainerBlogBackend.{Cover, Resource, Collection, AwsService}
  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackendWeb.Schemas.BaseResponse, as: BaseResponseSchema
  alias RainerBlogBackendWeb.Schemas.CoverSetParams

  tags(["covers"])

  # POST /api/cover/set
  # body: {"owner_type": "theme|chapter|article", "owner_id": "uuid", "resource_id": "uuid"}
  operation(:set,
    summary: "Set cover",
    description: "Set cover by owner type and resource.",
    request_body: {"Cover params", "application/json", CoverSetParams},
    responses: [
      ok: {"Cover", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def set(conn, %{
        "owner_type" => owner_type,
        "owner_id" => owner_id,
        "resource_id" => resource_id
      }) do
    case Resource.get_resource(resource_id) do
      nil ->
        json(conn, BaseResponse.generate(404, "resource not found", nil))

      _resource ->
        case Cover.set_cover(owner_type, owner_id, resource_id) do
          {:ok, cover} ->
            json(conn, BaseResponse.generate(200, "set cover ok", cover))

          {:error, changeset} ->
            errors =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                Enum.reduce(opts, msg, fn {k, v}, acc ->
                  String.replace(acc, "%{#{k}}", to_string(v))
                end)
              end)

            json(conn, BaseResponse.generate(400, "invalid params", errors))
        end
    end
  end

  # GET /api/cover/url?owner_type=theme&owner_id=...
  operation(:url,
    summary: "Get cover URL",
    description: "Get presigned URL by owner.",
    parameters: [
      owner_type: [
        in: :query,
        description: "Owner type",
        schema: %OpenApiSpex.Schema{type: :string}
      ],
      owner_id: [
        in: :query,
        description: "Owner ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"URL", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def url(conn, %{"owner_type" => owner_type, "owner_id" => owner_id}) do
    case Cover.get_presigned_url_by_owner(owner_type, owner_id) do
      {:ok, {:ok, url}} ->
        # 处理嵌套的 {:ok, {:ok, url}} 结构
        json(conn, BaseResponse.generate(200, "ok", %{url: url}))

      {:ok, url} when is_binary(url) ->
        # 如果已经是字符串，直接使用
        json(conn, BaseResponse.generate(200, "ok", %{url: url}))

      {:error, :not_found} ->
        json(conn, BaseResponse.generate(404, "cover not found", nil))

      {:error, :resource_not_found} ->
        json(conn, BaseResponse.generate(404, "resource not found", nil))

      {:error, reason} ->
        json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # DELETE /api/cover?owner_type=theme&owner_id=...
  operation(:delete,
    summary: "Delete cover",
    description: "Delete cover by owner.",
    parameters: [
      owner_type: [
        in: :query,
        description: "Owner type",
        schema: %OpenApiSpex.Schema{type: :string}
      ],
      owner_id: [
        in: :query,
        description: "Owner ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Deleted", "application/json", BaseResponseSchema}
    ]
  )

  def delete(conn, %{"owner_type" => owner_type, "owner_id" => owner_id}) do
    case Cover.delete_by_owner(owner_type, owner_id) do
      {:ok, _} ->
        json(conn, BaseResponse.generate(200, "deleted", nil))

      {:error, reason} ->
        json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # GET /api/cover/articles?page=1&page_size=10
  operation(:articles,
    summary: "List article covers",
    description: "Get article covers with pagination.",
    parameters: [
      page: [
        in: :query,
        description: "Page number",
        schema: %OpenApiSpex.Schema{type: :integer, default: 1}
      ],
      page_size: [
        in: :query,
        description: "Page size",
        schema: %OpenApiSpex.Schema{type: :integer, default: 10}
      ]
    ],
    responses: [
      ok: {"Cover list", "application/json", BaseResponseSchema}
    ]
  )

  def articles(conn, params) do
    page = (params["page"] || 1) |> to_int()
    page_size = (params["page_size"] || 10) |> to_int()

    data = Cover.list_article_covers(page, page_size)
    json(conn, BaseResponse.generate(200, "ok", data))
  end

  # GET /api/cover/article/:id
  operation(:article,
    summary: "Get article cover",
    description: "Get cover by article ID.",
    parameters: [
      id: [
        in: :path,
        description: "Article ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Cover", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def article(conn, %{"id" => id}) do
    case Cover.get_cover_info("article", id) do
      {:ok, info} ->
        json(conn, BaseResponse.generate(200, "ok", info))

      {:error, :not_found} ->
        json(conn, BaseResponse.generate(404, "cover not found", nil))

      {:error, :resource_not_found} ->
        json(conn, BaseResponse.generate(404, "resource not found", nil))

      {:error, reason} ->
        json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # GET /api/cover/theme/:id
  operation(:theme,
    summary: "Get theme cover",
    description: "Get cover by theme ID.",
    parameters: [
      id: [
        in: :path,
        description: "Theme ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Cover", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def theme(conn, %{"id" => id}) do
    case Cover.get_cover_info("theme", id) do
      {:ok, info} ->
        json(conn, BaseResponse.generate(200, "ok", info))

      {:error, :not_found} ->
        json(conn, BaseResponse.generate(404, "cover not found", nil))

      {:error, :resource_not_found} ->
        json(conn, BaseResponse.generate(404, "resource not found", nil))

      {:error, reason} ->
        json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # GET /api/cover/chapter/:id
  operation(:chapter,
    summary: "Get chapter cover",
    description: "Get cover by chapter ID.",
    parameters: [
      id: [
        in: :path,
        description: "Chapter ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Cover", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def chapter(conn, %{"id" => id}) do
    case Cover.get_cover_info("chapter", id) do
      {:ok, info} ->
        json(conn, BaseResponse.generate(200, "ok", info))

      {:error, :not_found} ->
        json(conn, BaseResponse.generate(404, "cover not found", nil))

      {:error, :resource_not_found} ->
        json(conn, BaseResponse.generate(404, "resource not found", nil))

      {:error, reason} ->
        json(conn, BaseResponse.generate(500, "failed", %{error: inspect(reason)}))
    end
  end

  # GET /api/cover/theme/:id/chapters
  operation(:theme_chapters,
    summary: "Get theme chapter covers",
    description: "Get chapter covers by theme ID.",
    parameters: [
      id: [
        in: :path,
        description: "Theme ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Cover list", "application/json", BaseResponseSchema}
    ]
  )

  def theme_chapters(conn, %{"id" => id}) do
    data = Cover.get_chapter_covers_by_theme(id)
    json(conn, BaseResponse.generate(200, "ok", data))
  end

  # GET /api/cover/chapter/:id/articles
  operation(:chapter_articles,
    summary: "Get chapter article covers",
    description: "Get article covers by chapter ID.",
    parameters: [
      id: [
        in: :path,
        description: "Chapter ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Cover list", "application/json", BaseResponseSchema}
    ]
  )

  def chapter_articles(conn, %{"id" => id}) do
    data = Cover.get_article_covers_by_chapter(id)
    json(conn, BaseResponse.generate(200, "ok", data))
  end

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1

  # GET /api/cover/resources?page=1&page_size=20
  # 获取所有可用的封面资源列表（从 covers collection）
  operation(:resources,
    summary: "List cover resources",
    description: "Get available cover resources with pagination.",
    parameters: [
      page: [
        in: :query,
        description: "Page number",
        schema: %OpenApiSpex.Schema{type: :integer, default: 1}
      ],
      page_size: [
        in: :query,
        description: "Page size",
        schema: %OpenApiSpex.Schema{type: :integer, default: 20}
      ]
    ],
    responses: [
      ok: {"Resources", "application/json", BaseResponseSchema}
    ]
  )

  def resources(conn, params) do
    page = (params["page"] || 1) |> to_int()
    page_size = (params["page_size"] || 20) |> to_int()

    case Collection.get_by_name("covers") do
      nil ->
        json(
          conn,
          BaseResponse.generate(200, "ok", %{
            resources: [],
            total: 0,
            page: page,
            page_size: page_size
          })
        )

      collection ->
        resources = Resource.list_by_collection(collection.id, page: page, page_size: page_size)
        total = Resource.count_by_collection(collection.id)

        # 为每个资源生成预签名 URL
        resources_with_urls =
          Enum.map(resources, fn resource ->
            case AwsService.generate_presigned_url(resource.aws_key, 3600) do
              {:ok, url} ->
                Map.from_struct(resource)
                |> Map.put(:url, url)
                |> Map.take([
                  :id,
                  :name,
                  :description,
                  :file_type,
                  :file_size,
                  :aws_key,
                  :url,
                  :inserted_at
                ])

              {:error, _} ->
                Map.from_struct(resource)
                |> Map.put(:url, nil)
                |> Map.take([
                  :id,
                  :name,
                  :description,
                  :file_type,
                  :file_size,
                  :aws_key,
                  :url,
                  :inserted_at
                ])
            end
          end)

        json(
          conn,
          BaseResponse.generate(200, "ok", %{
            resources: resources_with_urls,
            total: total,
            page: page,
            page_size: page_size,
            total_pages: ceil(total / page_size)
          })
        )
    end
  end

  # POST /api/cover/upload_set
  # multipart form-data: file + owner_type + owner_id
  operation(:upload_set,
    summary: "Upload and set cover",
    description: "Upload cover image and set it for an owner (multipart/form-data).",
    responses: [
      ok: {"Cover", "application/json", BaseResponseSchema},
      bad_request: {"Bad Request", "application/json", BaseResponseSchema}
    ]
  )

  def upload_set(
        conn,
        %{"file" => file_param, "owner_type" => owner_type, "owner_id" => owner_id} = params
      ) do
    filename = file_param.filename
    content = file_param.path |> File.read!()
    file_size = byte_size(content)
    file_type = params["file_type"] || get_file_type(filename)

    # 获取或创建封面专用的 collection
    {:ok, covers_collection} = Collection.get_or_create_covers_collection()

    # generate aws_key
    uuid = Ecto.UUID.generate()
    ext = filename |> Path.extname() |> String.downcase()
    aws_key = "resources/#{uuid}#{ext}"

    # 为文件名添加时间戳，避免在 collection 中重名
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    unique_name = params["name"] || "#{Path.basename(filename, ext)}_#{timestamp}#{ext}"

    # 检查是否已存在相同的 aws_key（理论上不会重复，因为使用了UUID）
    # 未来可以通过文件 hash 来检查是否上传过相同内容的文件
    case Resource.get_by_aws_key(aws_key) do
      nil ->
        # 不存在，上传新文件
        case AwsService.upload_content(content, aws_key) do
          {:ok, _s3_path} ->
            attrs = %{
              name: unique_name,
              description: params["description"] || filename,
              file_type: file_type,
              file_size: file_size,
              aws_key: aws_key,
              order: params["order"] || 0,
              is_active: params["is_active"] || true,
              # 自动关联到 covers collection
              collection_id: covers_collection.id
            }

            case Resource.create_resource(attrs) do
              {:ok, resource} ->
                case Cover.set_cover(owner_type, owner_id, resource.id) do
                  {:ok, cover} ->
                    json(
                      conn,
                      BaseResponse.generate(201, "cover set successfully", %{
                        cover: cover,
                        resource: resource
                      })
                    )

                  {:error, changeset} ->
                    errors =
                      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                        Enum.reduce(opts, msg, fn {k, v}, acc ->
                          String.replace(acc, "%{#{k}}", to_string(v))
                        end)
                      end)

                    json(conn, BaseResponse.generate(400, "failed to set cover", errors))
                end

              {:error, changeset} ->
                errors =
                  Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                    Enum.reduce(opts, msg, fn {k, v}, acc ->
                      String.replace(acc, "%{#{k}}", to_string(v))
                    end)
                  end)

                json(conn, BaseResponse.generate(400, "invalid resource params", errors))
            end

          {:error, reason} ->
            json(conn, BaseResponse.generate(500, "S3 upload failed", %{error: inspect(reason)}))
        end

      existing_resource ->
        # 已存在相同的资源，直接复用
        case Cover.set_cover(owner_type, owner_id, existing_resource.id) do
          {:ok, cover} ->
            json(
              conn,
              BaseResponse.generate(200, "cover set successfully (reused existing resource)", %{
                cover: cover,
                resource: existing_resource
              })
            )

          {:error, changeset} ->
            errors =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                Enum.reduce(opts, msg, fn {k, v}, acc ->
                  String.replace(acc, "%{#{k}}", to_string(v))
                end)
              end)

            json(conn, BaseResponse.generate(400, "failed to set cover", errors))
        end
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
