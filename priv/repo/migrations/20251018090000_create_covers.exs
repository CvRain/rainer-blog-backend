defmodule RainerBlogBackend.Repo.Migrations.CreateCovers do
  use Ecto.Migration

  def change do
    create table(:covers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :owner_type, :string, null: false
      add :owner_id, :uuid, null: false
      add :resource_id, references(:resources, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:covers, [:resource_id])
    create unique_index(:covers, [:owner_type, :owner_id])
  end
end
