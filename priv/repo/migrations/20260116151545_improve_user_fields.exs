defmodule RainerBlogBackend.Repo.Migrations.ImproveUserFields do
  use Ecto.Migration

  def up do
    alter table(:users) do
      # 将 avatar 和 background 字段改为 text 类型以支持 base64
      modify :user_avatar, :text
      modify :user_background, :text

      # 添加新的 links 字段（JSONB 格式）
      add :links, :jsonb, default: "[]"
    end

    # 迁移现有的社交媒体数据到 links 字段
    execute """
    UPDATE users
    SET links = (
      SELECT jsonb_agg(link)
      FROM (
        SELECT jsonb_build_object('title', 'Website', 'url', user_website) as link
        WHERE user_website IS NOT NULL AND user_website != ''
        UNION ALL
        SELECT jsonb_build_object('title', 'GitHub', 'url', 'https://github.com/' || user_github) as link
        WHERE user_github IS NOT NULL AND user_github != ''
        UNION ALL
        SELECT jsonb_build_object('title', 'Twitter', 'url', 'https://twitter.com/' || user_twitter) as link
        WHERE user_twitter IS NOT NULL AND user_twitter != ''
      ) links
    )
    WHERE user_website IS NOT NULL OR user_github IS NOT NULL OR user_twitter IS NOT NULL
    """

    # 删除旧的社交媒体字段
    alter table(:users) do
      remove :user_website
      remove :user_github
      remove :user_twitter
    end
  end

  def down do
    alter table(:users) do
      # 恢复旧字段
      add :user_website, :string
      add :user_github, :string
      add :user_twitter, :string

      # 恢复 avatar 和 background 为 varchar
      modify :user_avatar, :string
      modify :user_background, :string
    end

    # 尝试恢复数据（简化版，可能丢失部分信息）
    execute """
    UPDATE users
    SET
      user_website = (SELECT value->>'url' FROM jsonb_array_elements(links) WHERE value->>'title' = 'Website' LIMIT 1),
      user_github = REPLACE((SELECT value->>'url' FROM jsonb_array_elements(links) WHERE value->>'title' = 'GitHub' LIMIT 1), 'https://github.com/', ''),
      user_twitter = REPLACE((SELECT value->>'url' FROM jsonb_array_elements(links) WHERE value->>'title' = 'Twitter' LIMIT 1), 'https://twitter.com/', '')
    WHERE links IS NOT NULL
    """

    alter table(:users) do
      remove :links
    end
  end
end
