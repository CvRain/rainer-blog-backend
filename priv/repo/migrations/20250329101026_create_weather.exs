defmodule RainerBlogBackend.Repo.Migrations.CreateWeather do
  use Ecto.Migration

  def change do
    create table(:weather) do
      add :city, :string
      add :temp_low, :string
      add :temp_high, :string
      add :prcp, :float

      timestamps(type: :utc_datetime)
    end
  end
end
