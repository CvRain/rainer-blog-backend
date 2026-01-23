defmodule RainerBlogBackend.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :file_type, :string, null: false
      add :file_size, :integer, null: false
      add :aws_key, :string, null: false
      add :order, :integer, default: 0
      add :is_active, :boolean, default: true

      add :collection_id, references(:collections, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:resources, [:collection_id])
    create unique_index(:resources, [:name, :collection_id])
    create unique_index(:resources, [:aws_key])
  end
end
