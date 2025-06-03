defmodule RainerBlogBackend.User do
  @moduledoc """
  用户模块，从配置文件读取用户信息
  """

  defstruct [:name, :password, :signature, :avatar, :background]

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

  @doc """
  获取用户信息
  """
  def get_user do
    config = Application.get_env(:rainer_blog_backend, :user)
    %__MODULE__{
      name: config[:name],
      password: config[:password],
      signature: config[:signature],
      avatar: config[:avatar],
      background: config[:background]
    }
  end

  @doc """
  验证用户密码
  """
  def verify_password(password) do
    user = get_user()
    Bcrypt.verify_pass(password, user.password)
  end

  @doc """
  更新用户信息
  """
  def update_user(attrs) do
    config = Application.get_env(:rainer_blog_backend, :user)
    new_config = Map.merge(config, attrs)
    Application.put_env(:rainer_blog_backend, :user, new_config)
    get_user()
  end
end
