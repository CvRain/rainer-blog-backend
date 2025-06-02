defmodule RainerBlogBackend.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chapters" do
    field :name, :string
    field :description, :string
    field :order, :integer
    field :is_active, :boolean, default: false
    field :theme_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chapter, attrs) do
    chapter
    |> cast(attrs, [:name, :description, :order, :is_active])
    |> validate_required([:name, :description, :order, :is_active])
  end
end
