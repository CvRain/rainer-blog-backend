defmodule RainerBlogBackend.Model do
  defmacro __using__(_) do
    quote do
      use Ecto.Model
      @primary_key {:id, :binary_id, autogenerate: true}
      # For associations
      @foreign_key_type :binary_id
    end
  end
end
