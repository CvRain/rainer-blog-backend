defmodule RainerBlogBackend.Repo.Migrations.AddCacheMetadataToArticleContentCache do
  use Ecto.Migration

  def change do
    alter table(:article_content_cache) do
      add :cached_at, :utc_datetime
      add :content_hash, :string
      add :expires_at, :utc_datetime
    end

    create index(:article_content_cache, [:cached_at])
    create index(:article_content_cache, [:expires_at])
    create index(:article_content_cache, [:content_hash])

    # 为现有记录设置默认值
    execute(
      "UPDATE article_content_cache SET cached_at = last_updated, content_hash = md5(content)",
      "UPDATE article_content_cache SET cached_at = NULL, content_hash = NULL"
    )
  end
end
