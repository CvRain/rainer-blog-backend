defmodule RainerBlogBackend.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :order, :integer, default: 0
      add :is_active, :boolean, default: true

      timestamps()
    end

    create unique_index(:collections, [:name])
  end
end
