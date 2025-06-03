defmodule RainerBlogBackend.Theme do
  use Ecto.Schema
  import Ecto.Changeset
  alias RainerBlogBackend.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "themes" do
    field :name, :string
    field :description, :string
    field :order, :integer
    field :is_active, :boolean, default: false

    timestamps(type: :utc_datetime)
  end
  @doc false

  def changeset(theme, attrs) do
    theme
    |> cast(attrs, [:name, :description, :order, :is_active])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @spec create_theme(String.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_theme(name) do
    __MODULE__
    |> struct()
    |> changeset(%{name: name})
    |> Repo.insert()
  end
end
