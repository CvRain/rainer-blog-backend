defmodule RainerBlogBackendWeb.Types.User do
  alias RainerBlogBackend.ConfigStore
  @derive {Jason.Encoder, only: [:name, :email, :password, :signature, :avatar, :background]}
  defstruct [:name, :email, :password, :signature, :avatar, :background]

  def get_user() do
    with {:ok, name} <- ConfigStore.get(:name),
         {:ok, email} <- ConfigStore.get(:email),
         {:ok, password} <- ConfigStore.get(:password),
         {:ok, signature} <- ConfigStore.get(:signature),
         {:ok, avatar} <- ConfigStore.get(:avatar),
         {:ok, background} <- ConfigStore.get(:background) do
      {:ok, %__MODULE__{
        name: name,
        email: email,
        password: password,
        signature: signature,
        avatar: avatar,
        background: background
      }}
    else
      {:error, :not_found} -> {:error, :user_not_configured}
      {:error, reason} -> {:error, reason}
    end
  end

  def create_user(user) do
    with :ok <- ConfigStore.put(:name, user.name),
         :ok <- ConfigStore.put(:email, user.email),
         :ok <- ConfigStore.put(:password, user.password),
         :ok <- ConfigStore.put(:signature, user.signature),
         :ok <- ConfigStore.put(:avatar, user.avatar),
         :ok <- ConfigStore.put(:background, user.background) do
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
