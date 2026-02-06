defmodule RainerBlogBackendWeb.Schemas.Theme do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Theme",
    description: "A theme",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string},
      description: %Schema{type: :string, nullable: true},
      order: %Schema{type: :integer},
      is_active: %Schema{type: :boolean},
      inserted_at: %Schema{type: :string, format: :date_time},
      updated_at: %Schema{type: :string, format: :date_time}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.ThemeParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ThemeParams",
    description: "Parameters for creating a theme",
    type: :object,
    properties: %{
      name: %Schema{type: :string},
      description: %Schema{type: :string}
    },
    required: [:name, :description]
  })
end

defmodule RainerBlogBackendWeb.Schemas.ThemeUpdateParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ThemeUpdateParams",
    description: "Parameters for updating a theme",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string, nullable: true},
      description: %Schema{type: :string, nullable: true},
      order: %Schema{type: :integer, nullable: true},
      is_active: %Schema{type: :boolean, nullable: true}
    },
    required: [:id]
  })
end

defmodule RainerBlogBackendWeb.Schemas.ThemeResponse do
  alias RainerBlogBackendWeb.Schemas.Theme
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: Theme
end

defmodule RainerBlogBackendWeb.Schemas.ThemeListResponse do
  alias RainerBlogBackendWeb.Schemas.Theme
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: Theme, list: true
end
