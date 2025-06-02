defmodule RainerBlogBackend.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "collections" do
    field :name, :string
    field :description, :string
    field :order, :integer
    field :is_active, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name, :description, :order, :is_active])
    |> validate_required([:name, :description, :order, :is_active])
  end
end
