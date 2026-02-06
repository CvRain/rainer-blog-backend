defmodule RainerBlogBackendWeb.Schemas.Resource do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Resource",
    description: "A resource",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string},
      description: %Schema{type: :string, nullable: true},
      file_type: %Schema{type: :string},
      file_size: %Schema{type: :integer},
      aws_key: %Schema{type: :string},
      order: %Schema{type: :integer},
      is_active: %Schema{type: :boolean},
      collection_id: %Schema{type: :string, format: :uuid, nullable: true},
      inserted_at: %Schema{type: :string, format: :date_time},
      updated_at: %Schema{type: :string, format: :date_time}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.ResourceParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ResourceParams",
    description: "Parameters for creating a resource",
    type: :object,
    properties: %{
      name: %Schema{type: :string},
      description: %Schema{type: :string, nullable: true},
      file_type: %Schema{type: :string, nullable: true},
      file_size: %Schema{type: :integer, nullable: true},
      aws_key: %Schema{type: :string, nullable: true},
      order: %Schema{type: :integer, nullable: true},
      is_active: %Schema{type: :boolean, nullable: true},
      collection_id: %Schema{type: :string, format: :uuid, nullable: true}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.ResourceResponse do
  alias RainerBlogBackendWeb.Schemas.Resource
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: Resource
end

defmodule RainerBlogBackendWeb.Schemas.ResourceListResponse do
  alias RainerBlogBackendWeb.Schemas.Resource
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: Resource, list: true
end
