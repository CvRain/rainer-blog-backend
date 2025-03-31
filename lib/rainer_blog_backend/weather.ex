defmodule RainerBlogBackend.Weather do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:city, :temp_low, :temp_high, :prcp]}

  schema "weather" do
    field :city, :string
    field :temp_low, :integer
    field :temp_high, :integer
    field :prcp, :float

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(weather, attrs) do
    weather
    |> cast(attrs, [:city, :temp_low, :temp_high, :prcp])
    |> validate_required([:city, :temp_low, :temp_high, :prcp])
  end
end
