defmodule RainerBlogBackendWeb.Schemas.Chapter do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Chapter",
    description: "A chapter",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string},
      description: %Schema{type: :string, nullable: true},
      order: %Schema{type: :integer},
      is_active: %Schema{type: :boolean},
      theme_id: %Schema{type: :string, format: :uuid},
      inserted_at: %Schema{type: :string, format: :date_time},
      updated_at: %Schema{type: :string, format: :date_time}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.ChapterParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ChapterParams",
    description: "Parameters for creating a chapter",
    type: :object,
    properties: %{
      name: %Schema{type: :string},
      description: %Schema{type: :string, nullable: true},
      order: %Schema{type: :integer, nullable: true},
      is_active: %Schema{type: :boolean, nullable: true},
      theme_id: %Schema{type: :string, format: :uuid}
    },
    required: [:name, :theme_id]
  })
end

defmodule RainerBlogBackendWeb.Schemas.ChapterUpdateParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ChapterUpdateParams",
    description: "Parameters for updating a chapter",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string, nullable: true},
      description: %Schema{type: :string, nullable: true},
      order: %Schema{type: :integer, nullable: true},
      is_active: %Schema{type: :boolean, nullable: true},
      theme_id: %Schema{type: :string, format: :uuid, nullable: true}
    },
    required: [:id]
  })
end

defmodule RainerBlogBackendWeb.Schemas.ChapterResponse do
  alias RainerBlogBackendWeb.Schemas.Chapter
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: Chapter
end

defmodule RainerBlogBackendWeb.Schemas.ChapterListResponse do
  alias RainerBlogBackendWeb.Schemas.Chapter
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: Chapter, list: true
end
