defmodule RainerBlogBackend.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias RainerBlogBackend.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [:id, :name, :signature, :avatar, :background, :inserted_at, :updated_at]}
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
    |> validate_required([:name, :password])
    |> unique_constraint(:name)
    |> put_password_hash()
  end

  @spec create_user(String.t(), String.t()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_user(name, password) do
    __MODULE__
    |> struct()
    |> changeset(%{name: name, password: password})
    |> Repo.insert()
  end

  @spec delete_user(binary()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(id) do
    case Repo.get(__MODULE__, id) do
      nil -> {:error, "User not found"}
      user -> Repo.delete(user)
    end
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, password: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
