defmodule RainerBlogBackend.User do
  @moduledoc """
  用户模块，从配置文件读取用户信息
  """

  defstruct [:name, :password, :signature, :avatar, :background]

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

  @doc """
  检查用户是否存在
  """
  def user_exists? do
    config = Application.get_env(:rainer_blog_backend, :user)
    config != nil && config[:name] != nil && config[:password] != nil
  end

  @doc """
  创建新用户
  """
  def create_user(name, password) do
    config = %{
      name: name,
      password: Bcrypt.hash_pwd_salt(password),
      signature: "个人博客",
      avatar: "/images/default-avatar.png",
      background: "/images/default-background.jpg"
    }
    Application.put_env(:rainer_blog_backend, :user, config)
    get_user()
  end
end
