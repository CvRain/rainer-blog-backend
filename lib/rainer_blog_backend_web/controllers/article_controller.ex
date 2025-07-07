defmodule RainerBlogBackendWeb.ArticleController do
  alias RainerBlogBackendWeb.Types.BaseResponse
  use RainerBlogBackendWeb, :controller
  alias RainerBlogBackend.{Article, AwsService, Chapter}

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

  def create(conn, params) do
    title = params["title"]
    content = params["content"] || ""
    chapter_id = params["chapter_id"]

    cond do
      is_nil(title) or title == "" ->
        json(conn, BaseResponse.generate(400, "400BadRequest", "缺少文章标题"))
      is_nil(chapter_id) or chapter_id == "" ->
        json(conn, BaseResponse.generate(400, "400BadRequest", "缺少章节ID"))
      true ->
        # 检查chapter是否存在
        chapter = Chapter.get_by_theme(chapter_id, 1, 1) |> List.first() || Chapter.get_all(1, 1000) |> Enum.find(fn c -> c.id == chapter_id end)
        if is_nil(chapter) do
          json(conn, BaseResponse.generate(400, "400BadRequest", "章节不存在"))
        else
          # 生成aws_key
          uuid = Ecto.UUID.generate()
          aws_key = "articles/#{uuid}.md"
          file_content = "# \\#{title}\\n\\n#{content}"
          # 上传到S3
          case AwsService.upload_content(file_content, aws_key) do
            {:ok, _s3_path} ->
              attrs = %{
                title: title,
                content: content,
                aws_key: aws_key,
                order: params["order"] || 0,
                is_active: true,
                chapter_id: chapter_id
              }
              case Article.create(attrs) do
                {:ok, article} ->
                  json(conn, BaseResponse.generate(201, "201Created", article))
                {:error, changeset} ->
                  errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                    Enum.reduce(opts, msg, fn {key, value}, acc ->
                      String.replace(acc, "%{#{key}}", to_string(value))
                    end)
                  end)
                  json(conn, BaseResponse.generate(400, "400BadRequest", errors))
              end
            {:error, reason} ->
              json(conn, BaseResponse.generate(500, "500InternalServerError", "S3上传失败: #{inspect(reason)}"))
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

  def update(conn, %{"id" => id, "content" => new_content}) do
    case Article |> RainerBlogBackend.Repo.get(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "文章不存在"))
      article ->
        # 更新S3内容
        case AwsService.upload_content(new_content, article.aws_key) do
          {:ok, _} ->
            # 更新数据库content字段
            changeset = Ecto.Changeset.change(article, content: new_content)
            case RainerBlogBackend.Repo.update(changeset) do
              {:ok, updated} ->
                json(conn, BaseResponse.generate(200, "200OK", updated))
              {:error, changeset} ->
                errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                  Enum.reduce(opts, msg, fn {key, value}, acc ->
                    String.replace(acc, "%{#{key}}", to_string(value))
                  end)
                end)
                json(conn, BaseResponse.generate(400, "400BadRequest", errors))
            end
          {:error, reason} ->
            json(conn, BaseResponse.generate(500, "500InternalServerError", "S3更新失败: #{inspect(reason)}"))
        end
    end
  end
end
