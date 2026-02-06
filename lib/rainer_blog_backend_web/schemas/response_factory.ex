defmodule RainerBlogBackendWeb.Schemas.ResponseFactory do
  defmacro __using__(opts) do
    data_schema = Keyword.fetch!(opts, :data)
    is_list = Keyword.get(opts, :list, false)
    module_name = __CALLER__.module |> Module.split() |> List.last()

    quote do
      require OpenApiSpex
      alias OpenApiSpex.Schema

      # 计算 data 字段的 schema
      # 如果 data_schema 是模块名，直接使用
      # 如果 is_list 为 true，包裹在 array 中
      data_type =
        if unquote(is_list) do
          %Schema{type: :array, items: unquote(data_schema)}
        else
          unquote(data_schema)
        end

      OpenApiSpex.schema(%{
        title: unquote(module_name),
        description: "Standard response wrapper for #{unquote(module_name)}",
        type: :object,
        properties: %{
          code: %Schema{type: :integer, example: 200, description: "Status Code"},
          message: %Schema{type: :string, example: "OK", description: "Message"},
          data: data_type
        }
      })
    end
  end
end
