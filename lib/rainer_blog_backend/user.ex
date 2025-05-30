defmodule RainerBlogBackend.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :name, :string
    field :signature, :string
    field :password, :string
    field :avatar, :string
    field :background, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :password, :avatar, :signature, :background])
    |> validate_required([:name, :password, :avatar, :signature, :background])
    |> unique_constraint(:name)
  end
end
