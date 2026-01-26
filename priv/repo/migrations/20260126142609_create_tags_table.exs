defmodule RainerBlogBackend.Repo.Migrations.CreateTagsTable do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :color, :string
      add :slug, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:name])

    create table(:articles_tags, primary_key: false) do
      add :article_id, references(:articles, on_delete: :delete_all, type: :binary_id), null: false
      add :tag_id, references(:tags, on_delete: :delete_all, type: :binary_id), null: false
    end

    create unique_index(:articles_tags, [:article_id, :tag_id])
    create index(:articles_tags, [:tag_id])
  end
end
