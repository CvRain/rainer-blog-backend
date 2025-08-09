defmodule RainerBlogBackend.ArticleContentCache do
  @moduledoc """
  文章内容缓存模块
  用于缓存从S3获取的文章内容，减少对S3的直接请求
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias RainerBlogBackend.Repo
  alias RainerBlogBackend.Article

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "article_content_cache" do
    field :content, :string
    field :last_updated, :utc_datetime
    belongs_to :article, Article, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(cache, attrs) do
    cache
    |> cast(attrs, [:article_id, :content, :last_updated])
    |> validate_required([:article_id, :content, :last_updated])
  end

  @doc """
  根据文章ID获取缓存的内容
  """
  def get_by_article_id(article_id) do
    Repo.one(from c in __MODULE__, where: c.article_id == ^article_id)
  end

  @doc """
  创建或更新文章内容缓存
  """
  def upsert_content(article_id, content) do
    case get_by_article_id(article_id) do
      nil ->
        # 创建新缓存
        %__MODULE__{}
        |> changeset(%{
          article_id: article_id,
          content: content,
          last_updated: DateTime.utc_now()
        })
        |> Repo.insert()
      cache ->
        # 更新现有缓存
        cache
        |> changeset(%{
          content: content,
          last_updated: DateTime.utc_now()
        })
        |> Repo.update()
    end
  end

  @doc """
  删除指定文章的缓存
  """
  def delete_by_article_id(article_id) do
    case get_by_article_id(article_id) do
      nil -> {:ok, nil}
      cache -> Repo.delete(cache)
    end
  end
end