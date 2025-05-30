defmodule RainerBlogBackend.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :password, :string
      add :avatar, :string
      add :signature, :string
      add :background, :string

      timestamps(type: :utc_datetime)
    end
  end
end
