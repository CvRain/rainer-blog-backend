defmodule RainerBlogBackend.Article do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias RainerBlogBackend.Repo
  @doc """
    博客文章的结构
    - title: 文章标题
    - content: 文章梗概，可以不填
    - aws_key: aws格式的对象存储键
    - order: 排序字段
    - is_active: 是否激活，默认不激活
    - chapter_id: 所属章节
  """
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:id, :title, :content, :aws_key, :order, :is_active, :chapter_id, :inserted_at, :updated_at]}
  schema "articles" do
    field :title, :string
    field :content, :string
    field :aws_key, :string
    field :order, :integer
    field :is_active, :boolean, default: false
    field :chapter_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :content, :aws_key, :order, :is_active, :chapter_id])
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
  创建一个新的Article
  """
  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
