defmodule RainerBlogBackend.Models.Weather do
  use Ecto.Schema
  # see the note below for explanation of this line
  @primary_key {:id, :binary_id, autogenerate: true}

  # weather is the MongoDB collection name
  schema "weather" do
    field :city, :string
    field :temp_lo, :integer
    field :temp_hi, :integer
    field :prcp, :float, default: 0.0
  end
end
