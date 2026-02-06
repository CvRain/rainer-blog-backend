defmodule RainerBlogBackendWeb.Schemas.Collection do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Collection",
    description: "A collection",
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

defmodule RainerBlogBackendWeb.Schemas.CollectionParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CollectionParams",
    description: "Parameters for creating a collection",
    type: :object,
    properties: %{
      name: %Schema{type: :string},
      description: %Schema{type: :string, nullable: true},
      order: %Schema{type: :integer, nullable: true},
      is_active: %Schema{type: :boolean, nullable: true}
    },
    required: [:name]
  })
end

defmodule RainerBlogBackendWeb.Schemas.CollectionUpdateParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CollectionUpdateParams",
    description: "Parameters for updating a collection",
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

defmodule RainerBlogBackendWeb.Schemas.CollectionResponse do
  alias RainerBlogBackendWeb.Schemas.Collection
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: Collection
end

defmodule RainerBlogBackendWeb.Schemas.CollectionListResponse do
  alias RainerBlogBackendWeb.Schemas.Collection
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: Collection, list: true
end
