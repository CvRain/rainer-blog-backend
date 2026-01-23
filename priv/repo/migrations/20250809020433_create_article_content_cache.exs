defmodule RainerBlogBackend.Repo.Migrations.CreateArticleContentCache do
  use Ecto.Migration

  def change do
    create table(:article_content_cache, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :article_id, references(:articles, type: :uuid, on_delete: :delete_all), null: false
      add :content, :text, null: false
      add :last_updated, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:article_content_cache, [:article_id])
  end
end
