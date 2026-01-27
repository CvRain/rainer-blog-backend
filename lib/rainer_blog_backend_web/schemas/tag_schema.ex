defmodule RainerBlogBackendWeb.Schemas.Tag do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Tag",
    description: "A blog tag",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string},
      slug: %Schema{type: :string},
      color: %Schema{type: :string, nullable: true},
      inserted_at: %Schema{type: :string, format: :date_time},
      updated_at: %Schema{type: :string, format: :date_time}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.TagResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias RainerBlogBackendWeb.Schemas.Tag

  OpenApiSpex.schema(%{
    title: "TagResponse",
    description: "Response containing a list of tags",
    type: :object,
    properties: %{
      code: %Schema{type: :integer, example: 200},
      message: %Schema{type: :string, example: "OK"},
      data: %Schema{type: :array, items: Tag}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.TagDetailResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias RainerBlogBackendWeb.Schemas.Tag

  OpenApiSpex.schema(%{
    title: "TagDetailResponse",
    description: "Response containing tag details and articles",
    type: :object,
    properties: %{
      code: %Schema{type: :integer, example: 200},
      message: %Schema{type: :string, example: "OK"},
      data: %Schema{
        type: :object,
        properties: %{
          tag: Tag,
          articles: %Schema{type: :array, items: %Schema{type: :object, description: "Article"}}
        }
      }
    }
  })
end
