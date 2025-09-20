defmodule RainerBlogBackendWeb.ResourceController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.{Resource, AwsService}
  alias RainerBlogBackendWeb.Types.BaseResponse

  def index(conn, _params) do
    resources = Resource.list_resources()
    json(conn, BaseResponse.generate(200, "200Ok", resources))
  end

  def create(conn, %{"resource" => resource_params}) do
    with {:ok, %Resource{} = resource} <- Resource.create_resource(resource_params) do
      data = %{
        id: resource.id,
        name: resource.name,
        description: resource.description,
        file_type: resource.file_type,
        file_size: resource.file_size,
        aws_key: resource.aws_key,
        order: resource.order,
        is_active: resource.is_active,
        collection_id: resource.collection_id,
        inserted_at: resource.inserted_at,
        updated_at: resource.updated_at
      }

      conn
      |> put_status(:created)
      |> json(BaseResponse.generate(201, "资源创建成功", data))
    end
  end

  # 上传资源文件
  #   POST /api/resource/upload
  # Content-Type: multipart/form-data

  # file: [文件内容]
  # name: [可选的文件名]
  # description: [可选的描述]
  # file_type: [可选的文件类型]
  # order: [可选的排序]
  # is_active: [true|false，默认为 true]
  # collection_id: [可选的集合 ID]
  def upload(conn, %{"file" => file_param} = params) do
    # 获取文件信息
    filename = file_param.filename
    content = file_param.path |> File.read!()
    file_size = byte_size(content)
    file_type = params["file_type"] || get_file_type(filename)

    # 生成aws_key
    uuid = Ecto.UUID.generate()
    ext = filename |> Path.extname() |> String.downcase()
    aws_key = "resources/#{uuid}#{ext}"

    # 上传到S3
    case AwsService.upload_content(content, aws_key) do
      {:ok, _s3_path} ->
        # 保存到数据库
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
            data = %{
              id: resource.id,
              name: resource.name,
              description: resource.description,
              file_type: resource.file_type,
              file_size: resource.file_size,
              aws_key: resource.aws_key,
              order: resource.order,
              is_active: resource.is_active,
              collection_id: resource.collection_id,
              inserted_at: resource.inserted_at,
              updated_at: resource.updated_at
            }

            json(conn, BaseResponse.generate(201, "资源上传成功", data))

          {:error, changeset} ->
            errors =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                Enum.reduce(opts, msg, fn {key, value}, acc ->
                  String.replace(acc, "%{#{key}}", to_string(value))
                end)
              end)

            json(conn, BaseResponse.generate(400, "参数错误", errors))
        end

      {:error, reason} ->
        json(conn, BaseResponse.generate(500, "S3上传失败", %{error: inspect(reason)}))
    end
  end

  def show(conn, %{"id" => id}) do
    case Resource.get_resource(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "Resource not found", nil))

      resource ->
        data = %{
          id: resource.id,
          name: resource.name,
          description: resource.description,
          file_type: resource.file_type,
          file_size: resource.file_size,
          aws_key: resource.aws_key,
          order: resource.order,
          is_active: resource.is_active,
          collection_id: resource.collection_id,
          inserted_at: resource.inserted_at,
          updated_at: resource.updated_at
        }

        json(conn, BaseResponse.generate(200, "200Ok", data))
    end
  end

  # 下载资源文件
  def download(conn, %{"id" => id}) do
    case Resource.get_resource(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "Resource not found", nil))

      resource ->
        # 从S3下载内容
        case AwsService.download_content(resource.aws_key) do
          {:ok, content} ->
            conn
            |> put_resp_content_type(get_content_type(resource.file_type))
            |> put_resp_header("content-disposition", "attachment; filename=\"#{resource.name}\"")
            |> send_resp(200, content)

          {:error, reason} ->
            json(conn, BaseResponse.generate(500, "S3下载失败", %{error: inspect(reason)}))
        end
    end
  end

  # 获取资源的预签名URL
  def get_url(conn, %{"id" => id}) do
    case Resource.get_resource(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "Resource not found", nil))

      resource ->
        case AwsService.generate_presigned_url(resource.aws_key) do
          {:ok, url} ->
            data = %{
              id: resource.id,
              name: resource.name,
              url: url,
              file_type: resource.file_type
            }

            json(conn, BaseResponse.generate(200, "获取URL成功", data))

          {:error, reason} ->
            json(conn, BaseResponse.generate(500, "生成URL失败", %{error: inspect(reason)}))
        end
    end
  end

  # 获取资源的Base64编码内容
  def get_base64(conn, %{"id" => id}) do
    case Resource.get_resource(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "Resource not found", nil))

      resource ->
        case AwsService.get_base64_content(resource.aws_key) do
          {:ok, base64_content} ->
            data = %{
              id: resource.id,
              name: resource.name,
              base64_content: base64_content,
              file_type: resource.file_type
            }

            json(conn, BaseResponse.generate(200, "获取Base64内容成功", data))

          {:error, reason} ->
            json(conn, BaseResponse.generate(500, "获取Base64内容失败", %{error: inspect(reason)}))
        end
    end
  end

  def update(conn, %{"id" => id, "resource" => resource_params}) do
    case Resource.get_resource(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "Resource not found", nil))

      resource ->
        with {:ok, %Resource{} = resource} <- Resource.update_resource(resource, resource_params) do
          data = %{
            id: resource.id,
            name: resource.name,
            description: resource.description,
            file_type: resource.file_type,
            file_size: resource.file_size,
            aws_key: resource.aws_key,
            order: resource.order,
            is_active: resource.is_active,
            collection_id: resource.collection_id,
            inserted_at: resource.inserted_at,
            updated_at: resource.updated_at
          }

          json(conn, BaseResponse.generate(200, "资源更新成功", data))
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Resource.get_resource(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "Resource not found", nil))

      resource ->
        # 先尝试删除S3文件
        _ = AwsService.delete_content(resource.aws_key)

        with {:ok, %Resource{}} <- Resource.delete_resource(resource) do
          json(conn, BaseResponse.generate(200, "资源删除成功", nil))
        end
    end
  end

  # 根据文件名获取文件类型
  defp get_file_type(filename) do
    ext = filename |> Path.extname() |> String.downcase()

    case ext do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".pdf" -> "application/pdf"
      ".txt" -> "text/plain"
      ".md" -> "text/markdown"
      ".zip" -> "application/zip"
      ".tar" -> "application/x-tar"
      ".gz" -> "application/gzip"
      _ -> "application/octet-stream"
    end
  end

  # 根据文件类型获取content-type
  defp get_content_type(file_type) do
    file_type || "application/octet-stream"
  end
end
