defmodule RainerBlogBackendWeb.Schemas.Article do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Article",
    description: "A blog article",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      title: %Schema{type: :string},
      subtitle: %Schema{type: :string, nullable: true},
      aws_key: %Schema{type: :string},
      order: %Schema{type: :integer},
      is_active: %Schema{type: :boolean},
      chapter_id: %Schema{type: :string, format: :uuid},
      s3_content: %Schema{
        type: :string,
        description: "Content of the article loaded from S3",
        nullable: true
      },
      inserted_at: %Schema{type: :string, format: :date_time},
      updated_at: %Schema{type: :string, format: :date_time}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.ArticleParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ArticleParams",
    description: "Parameters for creating or updating an article",
    type: :object,
    properties: %{
      title: %Schema{type: :string},
      subtitle: %Schema{type: :string, nullable: true},
      chapter_id: %Schema{type: :string, format: :uuid},
      order: %Schema{type: :integer, nullable: true},
      tags: %Schema{type: :array, items: %Schema{type: :string}, nullable: true}
    },
    required: [:title, :chapter_id]
  })
end

defmodule RainerBlogBackendWeb.Schemas.ArticleUpdateParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ArticleUpdateParams",
    description: "Parameters for updating an article",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid},
      title: %Schema{type: :string, nullable: true},
      subtitle: %Schema{type: :string, nullable: true},
      s3_content: %Schema{type: :string, nullable: true},
      order: %Schema{type: :integer, nullable: true},
      is_active: %Schema{type: :boolean, nullable: true},
      chapter_id: %Schema{type: :string, format: :uuid, nullable: true},
      tags: %Schema{type: :array, items: %Schema{type: :string}, nullable: true}
    },
    required: [:id]
  })
end

defmodule RainerBlogBackendWeb.Schemas.ArticleResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias RainerBlogBackendWeb.Schemas.Article

  OpenApiSpex.schema(%{
    title: "ArticleResponse",
    description: "Response containing a single article",
    type: :object,
    properties: %{
      code: %Schema{type: :integer, example: 200},
      message: %Schema{type: :string, example: "OK"},
      data: Article
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.ArticleCountResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ArticleCountResponse",
    description: "Response containing count",
    type: :object,
    properties: %{
      code: %Schema{type: :integer, example: 200},
      message: %Schema{type: :string, example: "OK"},
      data: %Schema{
        type: :object,
        properties: %{
          count: %Schema{type: :integer}
        }
      }
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.ArticleListResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias RainerBlogBackendWeb.Schemas.Article

  OpenApiSpex.schema(%{
    title: "ArticleListResponse",
    description: "Response containing a list of articles",
    type: :object,
    properties: %{
      code: %Schema{type: :integer, example: 200},
      message: %Schema{type: :string, example: "OK"},
      data: %Schema{type: :array, items: Article}
    }
  })
end
