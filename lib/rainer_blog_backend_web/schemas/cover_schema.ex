defmodule RainerBlogBackendWeb.Schemas.CoverSetParams do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CoverSetParams",
    description: "Parameters for setting a cover",
    type: :object,
    properties: %{
      owner_type: %Schema{type: :string, description: "theme|chapter|article"},
      owner_id: %Schema{type: :string, format: :uuid},
      resource_id: %Schema{type: :string, format: :uuid}
    },
    required: [:owner_type, :owner_id, :resource_id]
  })
end
