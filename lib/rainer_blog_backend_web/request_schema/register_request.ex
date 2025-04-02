defmodule RainerBlogBackendWeb.RequestSchema.RegisterRequest do
  use Ecto.Schema

  import Ecto.Changeset

  @email_regex ~r/^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$/

  embedded_schema do
    field :name, :string
    field :email, :string
    field :password, :string
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> validate_length(:name, min: 2, max: 20)
    |> validate_length(:email, min: 5, max: 50)
    |> validate_length(:password, min: 6, max: 20)
    |> validate_format(:email, @email_regex, message: "邮箱格式无效")
    |> validate_password_strength()
  end

  defp validate_password_strength(changeset) do
    validate_change(changeset, :password, fn :password, password ->
      case strong_password?(password) do
        true -> []
        false -> [password: "至少需要包含数字和字母"]
      end
    end)
  end

  defp strong_password?(password) do
    String.match?(password, ~r/[A-Za-z]/) && String.match?(password, ~r/\d/)
  end
end
