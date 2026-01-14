defmodule RainerBlogBackend.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def up do
    # 重命名现有字段以匹配新的命名规范
    rename table(:users), :name, to: :user_name
    rename table(:users), :password, to: :user_password
    rename table(:users), :avatar, to: :user_avatar
    rename table(:users), :signature, to: :user_signature
    rename table(:users), :background, to: :user_background

    # 添加user_email字段（必填）
    alter table(:users) do
      add :user_email, :string
      add :user_nickname, :string
      add :user_bio, :text
      add :user_website, :string
      add :user_github, :string
      add :user_twitter, :string
      add :user_location, :string
      add :is_active, :boolean, default: true
    end

    # 为现有用户设置默认邮箱
    execute "UPDATE users SET user_email = user_name || '@rainerblog.com' WHERE user_email IS NULL"

    # 添加NOT NULL约束
    alter table(:users) do
      modify :user_name, :string, null: false
      modify :user_password, :string, null: false
      modify :user_email, :string, null: false
    end

    # 创建唯一索引
    create unique_index(:users, [:user_name])
    create unique_index(:users, [:user_email])
  end

  def down do
    # 删除索引
    drop_if_exists unique_index(:users, [:user_name])
    drop_if_exists unique_index(:users, [:user_email])

    # 删除新添加的字段
    alter table(:users) do
      remove :user_email
      remove :user_nickname
      remove :user_bio
      remove :user_website
      remove :user_github
      remove :user_twitter
      remove :user_location
      remove :is_active
    end

    # 恢复原字段名
    rename table(:users), :user_name, to: :name
    rename table(:users), :user_password, to: :password
    rename table(:users), :user_avatar, to: :avatar
    rename table(:users), :user_signature, to: :signature
    rename table(:users), :user_background, to: :background
  end
end
