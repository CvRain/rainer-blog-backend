defmodule RainerBlogBackendWeb.Schemas.S3Config do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "S3Config",
    description: "S3/OBS configuration",
    type: :object,
    properties: %{
      access_key_id: %Schema{type: :string},
      secret_access_key: %Schema{type: :string},
      region: %Schema{type: :string},
      bucket: %Schema{type: :string},
      endpoint: %Schema{type: :string}
    }
  })
end

defmodule RainerBlogBackendWeb.Schemas.S3ConfigResponse do
  use RainerBlogBackendWeb.Schemas.ResponseFactory, data: RainerBlogBackendWeb.Schemas.S3Config
end
