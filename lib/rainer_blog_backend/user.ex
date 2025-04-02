defmodule RainerBlogBackend.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @email_regex ~r/^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$/
  @derive {Jason.Encoder, only: [:id, :name, :email, :password, :signature, :avatar, :background]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string
    # 可选字段
    field :signature, :string
    # 可选字段
    field :avatar, :string
    # 可选字段
    field :background, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :signature, :avatar, :background])
    # 必填字段：name, email, password
    |> validate_required([:name, :email, :password])
    # 验证邮箱格式
    |> validate_format(:email, @email_regex, message: "邮箱格式无效")
    # 唯一性约束（需配合数据库唯一索引）
    |> unique_constraint(:email)
    |> unique_constraint(:name)
  end

  def add_user(attrs) do
    hashed_password = Bcrypt.hash_pwd_salt(attrs[:password] || attrs["password"])

    %RainerBlogBackend.User{}
    |> changeset(attrs)
    |> Ecto.Changeset.put_change(:password, hashed_password)
    |> RainerBlogBackend.Repo.insert()
  end

  def exist_by_id(id) do
    RainerBlogBackend.Repo.exists?(from u in RainerBlogBackend.User, where: u.id == ^id)
  end

  def exist_by_email(email) do
    RainerBlogBackend.Repo.exists?(from u in RainerBlogBackend.User, where: u.email == ^email)
  end

  def exist_by_name(name) do
    RainerBlogBackend.Repo.exists?(from u in RainerBlogBackend.User, where: u.name == ^name)
  end
end
