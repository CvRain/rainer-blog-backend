defmodule RainerBlogBackend.Article do
  @doc """
    博客文章的结构
    - title: 文章标题
    - subtitle: 文章副标题，可以不填
    - aws_key: aws格式的对象存储键
    - order: 排序字段
    - is_active: 是否激活，默认不激活
    - chapter_id: 所属章节
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias RainerBlogBackend.Repo
  alias RainerBlogBackend.ArticleContentCache

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [
             :id,
             :title,
             :subtitle,
             :aws_key,
             :order,
             :is_active,
             :chapter_id,
             :inserted_at,
             :updated_at
           ]}
  schema "articles" do
    field :title, :string
    field :subtitle, :string
    field :aws_key, :string
    field :order, :integer
    field :is_active, :boolean, default: false
    field :chapter_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :subtitle, :aws_key, :order, :is_active, :chapter_id])
    |> validate_required([:title, :aws_key, :order, :is_active, :chapter_id])
  end

  @doc """
    获取存在的article个数
  """
  @spec count() :: integer()
  def count() do
    Repo.aggregate(RainerBlogBackend.Article, :count, :id)
  end

  @doc """
    获取本周创建的article个数
  """
  @spec count_append_weekly() :: integer()
  def count_append_weekly() do
    now = DateTime.utc_now()
    start_of_week = DateTime.add(now, -DateTime.to_unix(now) |> rem(7 * 24 * 60 * 60), :second)

    __MODULE__
    |> where([a], a.inserted_at >= ^start_of_week)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
    获取指定chapter下的所有文章
  """
  @spec get_by_chapter(String.t()) :: [Ecto.Schema.t()]
  def get_by_chapter(chapter_id) do
    __MODULE__
    |> where([a], a.chapter_id == ^chapter_id)
    |> order_by([a], asc: a.order)
    |> Repo.all()
  end

  @doc """
    获取指定chapter下激活的文章
  """
  @spec get_active_by_chapter(String.t()) :: [Ecto.Schema.t()]
  def get_active_by_chapter(chapter_id) do
    __MODULE__
    |> where([a], a.chapter_id == ^chapter_id and a.is_active == true)
    |> order_by([a], asc: a.order)
    |> Repo.all()
  end

  @doc """
  获取一篇公开的文章（文章、章节、主题都必须是激活状态）
  """
  @spec get_public_article(String.t()) :: Ecto.Schema.t() | nil
  def get_public_article(id) do
    from(
      a in __MODULE__,
      join: c in "chapters",
      on: a.chapter_id == c.id,
      join: t in "themes",
      on: c.theme_id == t.id,
      where: a.id == ^id and a.is_active == true and c.is_active == true and t.is_active == true,
      select: a
    )
    |> Repo.one()
  end

  @doc """
  创建一个新的Article
  """
  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  删除文章
  """
  def delete(%__MODULE__{} = article) do
    # 删除文章时同时删除缓存
    ArticleContentCache.delete_by_article_id(article.id)
    Repo.delete(article)
  end

  @doc """
  获取公开的文章列表（文章、章节、主题都必须是激活状态），支持分页
  """
  @spec list_public_articles(integer(), integer()) :: [Ecto.Schema.t()]
  def list_public_articles(page \\ 1, page_size \\ 10) do
    query =
      from(
        a in __MODULE__,
        join: c in "chapters",
        on: a.chapter_id == c.id,
        join: t in "themes",
        on: c.theme_id == t.id,
        where: a.is_active == true and c.is_active == true and t.is_active == true,
        order_by: [desc: a.inserted_at],
        select: a
      )

    query =
      if page_size == -1 do
        query
      else
        offset = (page - 1) * page_size
        from q in query, offset: ^offset, limit: ^page_size
      end

    Repo.all(query)
  end
end
