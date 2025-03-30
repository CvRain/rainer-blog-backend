defmodule RainerBlogBackend.Repo.Migrations.AddUniqueIndexToUsers do
  use Ecto.Migration

  def change do
    # 为 email 和 name 添加唯一索引
    create unique_index(:users, [:email], name: :users_email_unique)
    create unique_index(:users, [:name], name: :users_name_unique)
  end
end
