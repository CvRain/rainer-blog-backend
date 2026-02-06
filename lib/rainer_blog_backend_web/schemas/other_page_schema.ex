defmodule RainerBlogBackendWeb.Schemas.MainInfoResponse do
  use RainerBlogBackendWeb.Schemas.ResponseFactory,
    data: %OpenApiSpex.Schema{
      type: :object,
      properties: %{
        timestamp: %OpenApiSpex.Schema{type: :integer},
        method: %OpenApiSpex.Schema{type: :string},
        host: %OpenApiSpex.Schema{type: :string},
        port: %OpenApiSpex.Schema{type: :integer}
      }
    }
end
