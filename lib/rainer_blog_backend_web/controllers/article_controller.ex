defmodule RainerBlogBackendWeb.ArticleController do
  use RainerBlogBackendWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackend.{Article, AwsService, Chapter, ArticleContentCache, Tag}

  alias RainerBlogBackendWeb.Schemas.{
    ArticleResponse,
    ArticleListResponse,
    ArticleCountResponse,
    ArticleParams,
    ArticleUpdateParams
  }

  alias RainerBlogBackendWeb.Schemas.BaseResponse, as: BaseResponseSchema

  import Ecto.Query

  tags(["articles"])

  operation(:count,
    summary: "Get article count",
    description: "Get the total number of articles.",
    responses: [
      ok: {"Count", "application/json", ArticleCountResponse}
    ]
  )

  def count(conn, _params) do
    data = %{
      count: Article.count()
    }

    json(conn, BaseResponse.generate(200, "200Ok", data))
  end

  operation(:count_this_week,
    summary: "Get article count for this week",
    description: "Get the number of articles created this week.",
    responses: [
      ok: {"Count", "application/json", ArticleCountResponse}
    ]
  )

  def count_this_week(conn, _params) do
    data = %{
      count: Article.count_append_weekly()
    }

    json(conn, BaseResponse.generate(200, "200Ok", data))
  end

  operation(:create,
    summary: "Create an article",
    description: "Create a new article.",
    request_body: {"Article params", "application/json", ArticleParams},
    responses: [
      created: {"Article", "application/json", ArticleResponse},
      bad_request: {"Bad Request", "application/json", BaseResponseSchema}
    ]
  )

  def create(conn, _params) do
    request_body = conn.body_params
    title = request_body["title"]
    subtitle = request_body["subtitle"]
    chapter_id = request_body["chapter_id"]
    order = request_body["order"] || 0
    tags_list = request_body["tags"] || []

    cond do
      is_nil(title) or title == "" ->
        json(conn, BaseResponse.generate(400, "文章标题不存在", %{field: "title", error: "不能为空"}))

      is_nil(chapter_id) or chapter_id == "" ->
        json(conn, BaseResponse.generate(400, "章节ID不存在", %{field: "chapter_id", error: "不能为空"}))

      true ->
        # 检查chapter是否存在
        chapter =
          Chapter.get_by_theme(chapter_id, 1, 1) |> List.first() ||
            Chapter.get_all(1, 1000) |> Enum.find(fn c -> c.id == chapter_id end)

        if is_nil(chapter) do
          json(
            conn,
            BaseResponse.generate(400, "章节不存在", %{field: "chapter_id", error: "无效的章节ID"})
          )
        else
          # 生成aws_key
          uuid = Ecto.UUID.generate()
          aws_key = "articles/#{uuid}.md"
          file_content = "# #{title}\n\n#{subtitle || ""}"
          # 上传到S3
          case AwsService.upload_content(file_content, aws_key) do
            {:ok, _s3_path} ->
              attrs = %{
                title: title,
                subtitle: subtitle,
                aws_key: aws_key,
                order: order,
                is_active: true,
                chapter_id: chapter_id
              }

              res =
                if tags_list != [] do
                  tags = Tag.get_or_create_tags(tags_list)
                  Article.create_with_tags(attrs, tags)
                else
                  Article.create(attrs)
                end

              case res do
                {:ok, article} ->
                  # 返回更友好的结构
                  data = %{
                    id: article.id,
                    title: article.title,
                    subtitle: article.subtitle,
                    aws_key: article.aws_key,
                    chapter_id: article.chapter_id,
                    order: article.order,
                    is_active: article.is_active,
                    inserted_at: article.inserted_at,
                    updated_at: article.updated_at
                  }

                  json(conn, BaseResponse.generate(201, "文章创建成功", data))

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
    end
  end

  operation(:public_show,
    summary: "Get public article",
    description: "Get a public article by ID.",
    parameters: [
      id: [
        in: :path,
        description: "Article ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Article", "application/json", ArticleResponse},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def public_show(conn, %{"id" => id}) do
    case Article.get_public_article(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "文章不存在或未激活"))

      article ->
        render_article_response(conn, article)
    end
  end

  operation(:private_show,
    summary: "Get article (Admin)",
    description: "Get any article by ID (Admin only).",
    parameters: [
      id: [
        in: :path,
        description: "Article ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Article", "application/json", ArticleResponse},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def private_show(conn, %{"id" => id}) do
    case Article.get_article(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "文章不存在"))

      article ->
        render_article_response(conn, article)
    end
  end

  defp render_article_response(conn, article) do
    # 使用新的缓存API，自动处理TTL和刷新逻辑
    case ArticleContentCache.get_or_refresh(article.id, article.aws_key) do
      {:ok, content} ->
        data = %{
          id: article.id,
          title: article.title,
          subtitle: article.subtitle,
          aws_key: article.aws_key,
          chapter_id: article.chapter_id,
          s3_content: content,
          inserted_at: article.inserted_at,
          updated_at: article.updated_at,
          order: article.order,
          is_active: article.is_active
        }

        json(conn, BaseResponse.generate(200, "200OK", data))

      {:error, reason} ->
        json(
          conn,
          BaseResponse.generate(
            500,
            "500InternalServerError",
            "S3下载失败: #{inspect(reason)}"
          )
        )
    end
  end

  operation(:delete,
    summary: "Delete an article",
    description: "Delete an article by ID.",
    parameters: [
      id: [
        in: :path,
        description: "Article ID",
        schema: %OpenApiSpex.Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      ok: {"Deleted", "application/json", BaseResponseSchema},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def delete(conn, %{"id" => id}) do
    case Article |> RainerBlogBackend.Repo.get(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "文章不存在"))

      article ->
        # 先尝试删除S3文件
        _ = AwsService.delete_content(article.aws_key)
        # 删除数据库记录和缓存
        case Article.delete(article) do
          {:ok, _} ->
            json(conn, BaseResponse.generate(200, "200OK", "删除成功"))

          {:error, reason} ->
            json(
              conn,
              BaseResponse.generate(500, "500InternalServerError", "数据库删除失败: #{inspect(reason)}")
            )
        end
    end
  end

  operation(:update,
    summary: "Update an article",
    description: "Update an existing article.",
    request_body: {"Update params", "application/json", ArticleUpdateParams},
    responses: [
      ok: {"Article", "application/json", ArticleResponse},
      not_found: {"Not Found", "application/json", BaseResponseSchema}
    ]
  )

  def update(conn, _param) do
    request_body = conn.body_params
    id = request_body["id"]
    # 可选字段
    # 简介
    new_subtitle = request_body["subtitle"]
    # 正文
    new_s3_content = request_body["s3_content"]
    title = request_body["title"]
    order = request_body["order"]
    is_active = request_body["is_active"]
    chapter_id = request_body["chapter_id"]
    tags_list = request_body["tags"]

    case Article |> RainerBlogBackend.Repo.get(id) do
      nil ->
        json(conn, BaseResponse.generate(404, "404NotFound", "文章不存在"))

      article ->
        # 先更新 S3 正文内容（如有）
        s3_update_result =
          if not is_nil(new_s3_content) do
            case AwsService.upload_content(new_s3_content, article.aws_key) do
              {:ok, _} ->
                # 更新成功后删除缓存，让下次请求重新缓存最新内容
                ArticleContentCache.delete_by_article_id(article.id)
                :ok

              {:error, reason} ->
                # 失败时直接返回 conn，终止后续流程
                conn = json(conn, BaseResponse.generate(500, "S3更新失败", %{error: inspect(reason)}))
                # 直接 return conn
                {:error, conn}
            end
          else
            :ok
          end

        case s3_update_result do
          {:error, conn} ->
            # 如果已经返回了错误响应，直接返回conn
            conn

          _ ->
            # 构建要更新的字段
            update_attrs =
              %{}
              |> Map.merge(if is_nil(new_subtitle), do: %{}, else: %{subtitle: new_subtitle})
              |> Map.merge(if is_nil(title), do: %{}, else: %{title: title})
              |> Map.merge(if is_nil(order), do: %{}, else: %{order: order})
              |> Map.merge(if is_nil(is_active), do: %{}, else: %{is_active: is_active})
              |> Map.merge(if is_nil(chapter_id), do: %{}, else: %{chapter_id: chapter_id})

            changeset = Ecto.Changeset.change(article, update_attrs)

            res =
              if !is_nil(tags_list) do
                tags = Tag.get_or_create_tags(tags_list)
                Article.update_with_tags(article, update_attrs, tags)
              else
                RainerBlogBackend.Repo.update(changeset)
              end

            case res do
              {:ok, updated} ->
                data = %{
                  id: updated.id,
                  title: updated.title,
                  subtitle: updated.subtitle,
                  aws_key: updated.aws_key,
                  chapter_id: updated.chapter_id,
                  order: updated.order,
                  is_active: updated.is_active,
                  inserted_at: updated.inserted_at,
                  updated_at: updated.updated_at
                }

                json(conn, BaseResponse.generate(200, "文章更新成功", data))

              {:error, changeset} ->
                errors =
                  Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                    Enum.reduce(opts, msg, fn {key, value}, acc ->
                      String.replace(acc, "%{#{key}}", to_string(value))
                    end)
                  end)

                json(conn, BaseResponse.generate(400, "参数错误", errors))
            end
        end
    end
  end

  operation(:list,
    summary: "List all articles (Auth)",
    description: "List all articles (requires authentication).",
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
      ok: {"Article List", "application/json", ArticleListResponse}
    ]
  )

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

  operation(:public_list,
    summary: "List public articles",
    description: "List active articles from active chapters and themes.",
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
      ok: {"Article List", "application/json", ArticleListResponse}
    ]
  )

  # 公开接口：只返回 is_active 为 true 的文章，无需登录
  def public_list(conn, params) do
    page = (params["page"] || 1) |> to_int() |> max(1)
    page_size = (params["page_size"] || 10) |> to_int()

    articles =
      if page_size < 1 and page_size != -1 do
        []
      else
        Article.list_public_articles(page, page_size)
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
