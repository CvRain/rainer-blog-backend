defmodule RainerBlogBackend.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true, autogenerate: true
      # 必填
      add :name, :string, null: false
      # 必填
      add :email, :string, null: false
      # 必填
      add :password, :string, null: false
      # 允许为空
      add :signature, :string
      # 允许为空
      add :avatar, :string
      # 允许为空
      add :background, :string

      timestamps(type: :utc_datetime)
    end
  end
end
