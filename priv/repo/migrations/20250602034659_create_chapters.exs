defmodule RainerBlogBackend.Repo.Migrations.CreateChapters do
  use Ecto.Migration

  def change do
    create table(:chapters, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :order, :integer, default: 0
      add :is_active, :boolean, default: true
      add :theme_id, references(:themes, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:chapters, [:theme_id])
    create unique_index(:chapters, [:name, :theme_id])
  end
end
