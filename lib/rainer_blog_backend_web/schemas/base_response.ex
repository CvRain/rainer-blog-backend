defmodule RainerBlogBackendWeb.Schemas.BaseResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "BaseResponse",
    description: "Standard API Response Structure",
    type: :object,
    properties: %{
      code: %Schema{type: :integer, example: 200},
      message: %Schema{type: :string, example: "success"},
      data: %Schema{nullable: true, description: "Response payload"}
    }
  })
end
