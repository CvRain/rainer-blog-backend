defmodule RainerBlogBackendWeb.ArticleController do
  alias RainerBlogBackendWeb.Types.BaseResponse
  use RainerBlogBackendWeb, :controller
  alias RainerBlogBackend.{Article, AwsService, Chapter}
  import Ecto.Query

  def count(conn, _params) do
    data = %{
      count: Article.count()
    }
    json(conn, BaseResponse.generate(200, "200Ok", data))
  end

  def count_this_week(conn, _params) do
    data = %{
      count: Article.count_append_weekly()
    }
    json(conn, BaseResponse.generate(200, "200Ok", data))
  end

  def create(conn, _params) do
    request_body = conn.body_params
    title = request_body["title"]
    content = request_body["content"]
    chapter_id = request_body["chapter_id"]
    order = request_body["order"] || 0

    cond do
      is_nil(title) or title == "" ->
        json(conn, BaseResponse.generate(400, "文章标题不存在", %{field: "title", error: "不能为空"}))
      is_nil(chapter_id) or chapter_id == "" ->
        json(conn, BaseResponse.generate(400, "章节ID不存在", %{field: "chapter_id", error: "不能为空"}))
      true ->
        # 检查chapter是否存在
        chapter = Chapter.get_by_theme(chapter_id, 1, 1) |> List.first() || Chapter.get_all(1, 1000) |> Enum.find(fn c -> c.id == chapter_id end)
        if is_nil(chapter) do
          json(conn, BaseResponse.generate(400, "章节不存在", %{field: "chapter_id", error: "无效的章节ID"}))
        else
          # 生成aws_key
          uuid = Ecto.UUID.generate()
          aws_key = "articles/#{uuid}.md"
          file_content = "# #{title}\n\n#{content || ""}"
          # 上传到S3
          case AwsService.upload_content(file_content, aws_key) do
            {:ok, _s3_path} ->
              attrs = %{
                title: title,
                content: content,
                aws_key: aws_key,
                order: order,
                is_active: true,
                chapter_id: chapter_id
              }
              case Article.create(attrs) do
                {:ok, article} ->
                  # 返回更友好的结构
                  data = %{
                    id: article.id,
                    title: article.title,
                    content: article.content,
                    aws_key: article.aws_key,
                    chapter_id: article.chapter_id,
                    order: article.order,
                    is_active: article.is_active,
                    inserted_at: article.inserted_at,
                    updated_at: article.updated_at
                  }
                  json(conn, BaseResponse.generate(201, "文章创建成功", data))
                {:error, changeset} ->
                  errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
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
    end
  end

  def show(conn, %{"id" => id}) do
    case Article |> RainerBlogBackend.Repo.get(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "文章不存在"))
      article ->
        # 从S3下载内容
        case AwsService.download_content(article.aws_key) do
          {:ok, s3_content} ->
            data = %{
              id: article.id,
              title: article.title,
              content: article.content,
              aws_key: article.aws_key,
              chapter_id: article.chapter_id,
              s3_content: s3_content,
              inserted_at: article.inserted_at,
              updated_at: article.updated_at
            }
            json(conn, BaseResponse.generate(200, "200OK", data))
          {:error, reason} ->
            json(conn, BaseResponse.generate(500, "500InternalServerError", "S3下载失败: #{inspect(reason)}"))
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Article |> RainerBlogBackend.Repo.get(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "文章不存在"))
      article ->
        # 先尝试删除S3文件
        _ = AwsService.delete_content(article.aws_key)
        # 删除数据库记录
        case RainerBlogBackend.Repo.delete(article) do
          {:ok, _} ->
            json(conn, BaseResponse.generate(200, "200OK", "删除成功"))
          {:error, reason} ->
            json(conn, BaseResponse.generate(500, "500InternalServerError", "数据库删除失败: #{inspect(reason)}"))
        end
    end
  end

  def update(conn, _param) do
    request_body = conn.body_params
    id = request_body["id"]
    # 可选字段
    new_content = request_body["content"] # 简介
    new_s3_content = request_body["s3_content"] # 正文
    title = request_body["title"]
    order = request_body["order"]
    is_active = request_body["is_active"]
    chapter_id = request_body["chapter_id"]

    case Article |> RainerBlogBackend.Repo.get(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "文章不存在"))
      article ->
        # 先更新 S3 正文内容（如有）
        if not is_nil(new_s3_content) do
          case AwsService.upload_content(new_s3_content, article.aws_key) do
            {:ok, _} ->
              :ok
            {:error, reason} ->
              # 失败时直接返回 conn，终止后续流程
              conn = json(conn, BaseResponse.generate(500, "S3更新失败", %{error: inspect(reason)}))
              # 直接 return conn
              conn
          end
        end
        # 构建要更新的字段
        update_attrs =
          %{}
          |> Map.merge(if is_nil(new_content), do: %{}, else: %{content: new_content})
          |> Map.merge(if is_nil(title), do: %{}, else: %{title: title})
          |> Map.merge(if is_nil(order), do: %{}, else: %{order: order})
          |> Map.merge(if is_nil(is_active), do: %{}, else: %{is_active: is_active})
          |> Map.merge(if is_nil(chapter_id), do: %{}, else: %{chapter_id: chapter_id})

        changeset = Ecto.Changeset.change(article, update_attrs)
        case RainerBlogBackend.Repo.update(changeset) do
          {:ok, updated} ->
            data = %{
              id: updated.id,
              title: updated.title,
              content: updated.content,
              aws_key: updated.aws_key,
              chapter_id: updated.chapter_id,
              order: updated.order,
              is_active: updated.is_active,
              inserted_at: updated.inserted_at,
              updated_at: updated.updated_at
            }
            json(conn, BaseResponse.generate(200, "文章更新成功", data))
          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", to_string(value))
              end)
            end)
            json(conn, BaseResponse.generate(400, "参数错误", errors))
        end
    end
  end

  # 登录后可用的分页接口
  def list(conn, params) do
    page = (params["page"] || 1) |> to_int() |> max(1)
    page_size = (params["page_size"] || 10) |> to_int()

    articles =
      cond do
        page_size == -1 ->
          RainerBlogBackend.Repo.all(Article)
        page_size < 1 ->
          []
        true ->
          offset = (page - 1) * page_size
          query = from a in Article, limit: ^page_size, offset: ^offset
          RainerBlogBackend.Repo.all(query)
      end

    json(conn, BaseResponse.generate(200, "200OK", articles))
  end

  # 公开接口：只返回 is_active 为 true 的文章，无需登录
  def public_list(conn, params) do
    page = (params["page"] || 1) |> to_int() |> max(1)
    page_size = (params["page_size"] || 10) |> to_int()

    articles =
      cond do
        page_size == -1 ->
          from(a in Article, where: a.is_active == true) |> RainerBlogBackend.Repo.all()
        page_size < 1 ->
          []
        true ->
          offset = (page - 1) * page_size
          query = from a in Article, where: a.is_active == true, limit: ^page_size, offset: ^offset
          RainerBlogBackend.Repo.all(query)
      end

    json(conn, BaseResponse.generate(200, "200OK", articles))
  end

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> 1
    end
  end
  defp to_int(_), do: 1
end
