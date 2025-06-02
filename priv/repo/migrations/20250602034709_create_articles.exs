defmodule RainerBlogBackend.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, null: false
      add :content, :text
      add :aws_key, :string, null: false
      add :order, :integer, default: 0
      add :is_active, :boolean, default: true
      add :chapter_id, references(:chapters, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:articles, [:chapter_id])
    create unique_index(:articles, [:title, :chapter_id])
    create unique_index(:articles, [:aws_key])
  end
end
