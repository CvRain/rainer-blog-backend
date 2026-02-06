defmodule RainerBlogBackendWeb.Schemas.CountResponse do
  use RainerBlogBackendWeb.Schemas.ResponseFactory,
    data: %OpenApiSpex.Schema{
      type: :object,
      properties: %{count: %OpenApiSpex.Schema{type: :integer}}
    }
end

defmodule RainerBlogBackendWeb.Schemas.StorageOverviewResponse do
  use RainerBlogBackendWeb.Schemas.ResponseFactory,
    data: %OpenApiSpex.Schema{
      type: :object,
      properties: %{
        article_count: %OpenApiSpex.Schema{type: :integer},
        article_append_weekly: %OpenApiSpex.Schema{type: :integer},
        theme_count: %OpenApiSpex.Schema{type: :integer},
        theme_append_weekly: %OpenApiSpex.Schema{type: :integer},
        collection_count: %OpenApiSpex.Schema{type: :integer},
        collection_append_weekly: %OpenApiSpex.Schema{type: :integer},
        resource_count: %OpenApiSpex.Schema{type: :integer},
        resource_append_weekly: %OpenApiSpex.Schema{type: :integer}
      }
    }
end
