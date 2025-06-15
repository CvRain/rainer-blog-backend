defmodule RainerBlogBackend.Article do
  use Ecto.Schema
  import Ecto.Changeset

  @doc """
    博客文章的结构
    - title: 文章标题
    - content: 文章内容，实际上存放的文章链接
    - aws_key: aws格式的对象存储键
    - order: 排序字段
    - is_active: 是否激活，默认不激活
    - chapter_id: 所属章节
  """
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
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
    |> cast(attrs, [:title, :content, :aws_key, :order, :is_active])
    |> validate_required([:title, :content, :aws_key, :order, :is_active])
  end
end
