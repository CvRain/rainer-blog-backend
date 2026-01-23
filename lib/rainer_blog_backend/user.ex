defmodule RainerBlogBackend.User do
  @moduledoc """
  博客用户模型

  用户字段说明：
  - user_name: 用户名（唯一，用于登录）
  - user_email: 邮箱（唯一）
  - user_password: 加密后的密码
  - user_nickname: 显示昵称
  - user_signature: 个性签名（简短）
  - user_bio: 个人简介（详细）
  - user_avatar: 头像URL
  - user_background: 背景图URL
  - user_website: 个人网站
  - user_github: GitHub用户名
  - user_twitter: Twitter用户名
  - user_location: 所在地
  - is_active: 账号是否激活
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias RainerBlogBackend.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [
             :id,
             :user_name,
             :user_email,
             :user_nickname,
             :user_signature,
             :user_bio,
             :user_avatar,
             :user_background,
             :links,
             :user_location,
             :is_active,
             :inserted_at,
             :updated_at
           ]}
  schema "users" do
    field :user_name, :string
    field :user_email, :string
    field :user_password, :string
    field :user_nickname, :string
    field :user_signature, :string
    field :user_bio, :string
    # 现在支持 base64
    field :user_avatar, :string
    # 现在支持 base64
    field :user_background, :string
    # 存储链接列表 [{"title": "GitHub", "url": "..."}]
    field :links, {:array, :map}, default: []
    field :user_location, :string
    field :is_active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :user_name,
      :user_email,
      :user_password,
      :user_nickname,
      :user_signature,
      :user_bio,
      :user_avatar,
      :user_background,
      :links,
      :user_location,
      :is_active
    ])
    |> validate_required([:user_name, :user_email, :user_password])
    |> validate_format(:user_email, ~r/^[^\s]+@[^\s]+$/, message: "邮箱格式不正确")
    |> validate_length(:user_name, min: 2, max: 50)
    |> validate_length(:user_nickname, max: 50)
    |> validate_length(:user_signature, max: 200)
    |> validate_length(:user_bio, max: 2000)
    |> validate_links(:links)
    |> unique_constraint(:user_name)
    |> unique_constraint(:user_email)
  end

  @doc """
  用于更新用户信息的changeset，不包含密码字段
  """
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :user_email,
      :user_nickname,
      :user_signature,
      :user_bio,
      :user_avatar,
      :user_background,
      :links,
      :user_location,
      :is_active
    ])
    |> validate_format(:user_email, ~r/^[^\s]+@[^\s]+$/, message: "邮箱格式不正确")
    |> validate_length(:user_nickname, max: 50)
    |> validate_length(:user_signature, max: 200)
    |> validate_length(:user_bio, max: 2000)
    |> validate_links(:links)
    |> unique_constraint(:user_email)
  end

  @doc """
  用于修改密码的changeset
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:user_password])
    |> validate_required([:user_password])
    |> validate_length(:user_password, min: 6)
    |> put_password_hash()
  end

  defp validate_links(changeset, field) do
    validate_change(changeset, field, fn _, links ->
      if is_nil(links) or links == [] do
        []
      else
        validate_links_list(links)
      end
    end)
  end

  defp validate_links_list(links) when is_list(links) do
    links
    |> Enum.with_index()
    |> Enum.flat_map(fn {link, index} ->
      cond do
        not is_map(link) ->
          [{:links, "链接 #{index + 1} 必须是对象格式"}]

        not Map.has_key?(link, "title") and not Map.has_key?(link, :title) ->
          [{:links, "链接 #{index + 1} 缺少 title 字段"}]

        not Map.has_key?(link, "url") and not Map.has_key?(link, :url) ->
          [{:links, "链接 #{index + 1} 缺少 url 字段"}]

        true ->
          title = link["title"] || link[:title]
          url = link["url"] || link[:url]

          errors = []

          errors =
            if String.length(to_string(title)) > 50 do
              [{:links, "链接 #{index + 1} 的标题不能超过50个字符"} | errors]
            else
              errors
            end

          errors =
            case URI.parse(to_string(url)) do
              %URI{scheme: scheme} when scheme in ["http", "https"] -> errors
              _ -> [{:links, "链接 #{index + 1} 的URL格式不正确"} | errors]
            end

          errors
      end
    end)
  end

  defp validate_links_list(_), do: [{:links, "links 必须是数组格式"}]

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{user_password: password}} ->
        put_change(changeset, :user_password, Argon2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  @doc """
  获取第一个用户（博客系统通常只有一个用户）
  """
  def get_user do
    Repo.one(from u in __MODULE__, limit: 1)
  end

  @doc """
  根据ID获取用户
  """
  def get_user_by_id(id) do
    Repo.get(__MODULE__, id)
  end

  @doc """
  根据用户名获取用户
  """
  def get_user_by_username(user_name) do
    Repo.get_by(__MODULE__, user_name: user_name)
  end

  @doc """
  创建用户
  """
  def create_user(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> put_password_hash()
    |> Repo.insert()
  end

  @doc """
  更新用户信息（不包含密码）
  """
  def update_user(user, attrs) do
    user
    |> update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  修改用户密码
  """
  def update_password(user, new_password) do
    user
    |> password_changeset(%{user_password: new_password})
    |> Repo.update()
  end

  @doc """
  验证用户密码
  """
  def verify_password(user, password) do
    Argon2.verify_pass(password, user.user_password)
  end

  @doc """
  获取用户的安全信息（移除密码字段）
  """
  def safe_user(user) do
    Map.drop(user, [:user_password, :__meta__, :__struct__])
  end
end
