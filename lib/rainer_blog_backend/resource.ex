defmodule RainerBlogBackend.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "resources" do
    field :name, :string
    field :description, :string
    field :file_type, :string
    field :file_size, :integer
    field :aws_key, :string
    field :order, :integer
    field :is_active, :boolean, default: false
    field :collection_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:name, :description, :file_type, :file_size, :aws_key, :order, :is_active])
    |> validate_required([:name, :description, :file_type, :file_size, :aws_key, :order, :is_active])
  end
end
