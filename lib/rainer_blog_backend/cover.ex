defmodule RainerBlogBackend.Cover do
  @moduledoc """
  封面模型，用于为 theme/chapter/article 绑定 resource 作为封面。
  owner_type: "theme" | "chapter" | "article"
  owner_id: 对应 owner 的 uuid
  resource_id: 指向 resources 表的外键
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias RainerBlogBackend.{Repo, Resource, AwsService}

  @derive {Jason.Encoder, only: [:id, :owner_type, :owner_id, :resource_id, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "covers" do
    field :owner_type, :string
    field :owner_id, :binary_id
    field :resource_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @required [:owner_type, :owner_id, :resource_id]

  def changeset(cover, attrs) do
    cover
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_inclusion(:owner_type, ["theme", "chapter", "article"])
    |> unique_constraint([:owner_type, :owner_id], name: :covers_owner_type_owner_id_index)
  end

  @doc "根据 owner_type 和 owner_id 获取封面记录"
  def get_by_owner(owner_type, owner_id) do
    from(c in __MODULE__, where: c.owner_type == ^owner_type and c.owner_id == ^owner_id)
    |> Repo.one()
  end

  @doc "为 owner 创建/更新封面（resource_id 必须存在）"
  def set_cover(owner_type, owner_id, resource_id) do
    attrs = %{owner_type: owner_type, owner_id: owner_id, resource_id: resource_id}

    case get_by_owner(owner_type, owner_id) do
      nil ->
        %__MODULE__{}
        |> changeset(attrs)
        |> Repo.insert()

      cover ->
        cover
        |> changeset(attrs)
        |> Repo.update()
    end
  end

  @doc "删除指定 owner 的封面（同时不删除 resource）"
  def delete_by_owner(owner_type, owner_id) do
    case get_by_owner(owner_type, owner_id) do
      nil -> {:ok, nil}
      cover -> Repo.delete(cover)
    end
  end

  @doc "返回 owner 对应封面资源的 presigned url（如果存在）"
  def get_presigned_url_by_owner(owner_type, owner_id, expires_in \\ 3600) do
    case get_by_owner(owner_type, owner_id) do
      nil -> {:error, :not_found}

      %__MODULE__{resource_id: resource_id} ->
        case Resource.get_resource(resource_id) do
          nil -> {:error, :resource_not_found}

          resource ->
            case AwsService.generate_presigned_url(resource.aws_key, expires_in) do
              {:ok, url} -> {:ok, url}
              {:error, reason} -> {:error, reason}
            end
        end
    end
  end

  @doc "获取单个 owner 的封面信息（包含 resource 与 presigned url）"
  def get_cover_info(owner_type, owner_id, expires_in \\ 3600) do
    case get_by_owner(owner_type, owner_id) do
      nil -> {:error, :not_found}

      %__MODULE__{resource_id: resource_id} ->
        case Resource.get_resource(resource_id) do
          nil -> {:error, :resource_not_found}

          resource ->
            case AwsService.generate_presigned_url(resource.aws_key, expires_in) do
              {:ok, url} ->
                {:ok,
                 %{
                   owner_type: owner_type,
                   owner_id: owner_id,
                   resource: %{
                     id: resource.id,
                     name: resource.name,
                     file_type: resource.file_type,
                     file_size: resource.file_size,
                     aws_key: resource.aws_key,
                     url: url
                   }
                 }}

              {:error, reason} -> {:error, reason}
            end
        end
    end
  end

  @doc "分页获取所有 article 的封面信息（返回 items 和分页信息）"
  def list_article_covers(page \\ 1, page_size \\ 10, expires_in \\ 3600) do
    page = max(1, page)
    page_size = page_size
    offset = (page - 1) * page_size

    base_query = from(c in __MODULE__, where: c.owner_type == "article")

    total = Repo.aggregate(base_query, :count, :id)

    query =
      from(c in __MODULE__,
        where: c.owner_type == "article",
        join: r in Resource,
        on: r.id == c.resource_id,
        join: a in RainerBlogBackend.Article,
        on: a.id == c.owner_id,
        order_by: [desc: a.inserted_at],
        offset: ^offset,
        limit: ^page_size,
        select: {c, r, a.id, a.title}
      )

    results = Repo.all(query)

    items =
      Enum.map(results, fn {cover, resource, article_id, article_title} ->
        url =
          case AwsService.generate_presigned_url(resource.aws_key, expires_in) do
            {:ok, u} -> u
            _ -> nil
          end

        %{
          article_id: article_id,
          article_title: article_title,
          cover: %{
            id: cover.id,
            resource_id: resource.id,
            name: resource.name,
            file_type: resource.file_type,
            file_size: resource.file_size,
            url: url
          }
        }
      end)

    %{items: items, total: total, page: page, page_size: page_size}
  end

  @doc "为指定 theme 获取其下所有章节的封面信息（按章节返回，如果章节没有封面则返回 nil）"
  def get_chapter_covers_by_theme(theme_id, expires_in \\ 3600) do
    chapters =
      RainerBlogBackend.Chapter
      |> where([c], c.theme_id == ^theme_id)
      |> order_by([c], asc: c.order)
      |> Repo.all()

    Enum.map(chapters, fn chapter ->
      cover_info =
        case get_cover_info("chapter", chapter.id, expires_in) do
          {:ok, info} -> info
          _ -> nil
        end

      %{
        chapter_id: chapter.id,
        chapter_name: chapter.name,
        cover: cover_info
      }
    end)
  end

  @doc "为指定 chapter 获取其下所有文章的封面信息（按文章返回，如果文章没有封面则返回 nil）"
  def get_article_covers_by_chapter(chapter_id, expires_in \\ 3600) do
    articles = RainerBlogBackend.Article.get_by_chapter(chapter_id)

    Enum.map(articles, fn article ->
      cover_info =
        case get_cover_info("article", article.id, expires_in) do
          {:ok, info} -> info
          _ -> nil
        end

      %{
        article_id: article.id,
        article_title: article.title,
        cover: cover_info
      }
    end)
  end
end
