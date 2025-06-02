defmodule RainerBlogBackend.Article do
  use Ecto.Schema
  import Ecto.Changeset

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
