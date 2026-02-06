defmodule RainerBlogBackendWeb.Schemas.User do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "User",
    description: "User (safe fields)",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      user_name: %Schema{type: :string},
      user_email: %Schema{type: :string},
      user_nickname: %Schema{type: :string, nullable: true},
      user_signature: %Schema{type: :string, nullable: true},
      user_bio: %Schema{type: :string, nullable: true},
      user_avatar: %Schema{type: :string, nullable: true},
      user_background: %Schema{type: :string, nullable: true},
      links: %Schema{type: :array, items: %Schema{type: :object}, nullable: true},
      user_location: %Schema{type: :string, nullable: true},
      is_active: %Schema{type: :boolean},
      inserted_at: %Schema{type: :string, format: :date_time},
      updated_at: %Schema{type: :string, format: :date_time}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.UserLoginParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UserLoginParams",
    description: "Login params",
    type: :object,
    properties: %{
      user_name: %Schema{type: :string},
      user_password: %Schema{type: :string}
    },
    required: [:user_name, :user_password]
  })
end

defmodule RainerBlogBackendWeb.Schemas.UserUpdateParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UserUpdateParams",
    description: "User update params",
    type: :object,
    properties: %{
      user_email: %Schema{type: :string, nullable: true},
      user_nickname: %Schema{type: :string, nullable: true},
      user_signature: %Schema{type: :string, nullable: true},
      user_bio: %Schema{type: :string, nullable: true},
      user_avatar: %Schema{type: :string, nullable: true},
      user_background: %Schema{type: :string, nullable: true},
      links: %Schema{type: :array, items: %Schema{type: :object}, nullable: true},
      user_location: %Schema{type: :string, nullable: true},
      is_active: %Schema{type: :boolean, nullable: true},
      user_password: %Schema{type: :string, nullable: true}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.UserResponse do
  alias RainerBlogBackendWeb.Schemas.User
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: User
end

defmodule RainerBlogBackendWeb.Schemas.UserLoginResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias RainerBlogBackendWeb.Schemas.User

  OpenApiSpex.schema(%{
    title: "UserLoginResponse",
    description: "Login response",
    type: :object,
    properties: %{
      code: %Schema{type: :integer, example: 200},
      message: %Schema{type: :string, example: "OK"},
      data: %Schema{
        type: :object,
        properties: %{
          user: User,
          token: %Schema{type: :string}
        }
      }
    }
  })
end
