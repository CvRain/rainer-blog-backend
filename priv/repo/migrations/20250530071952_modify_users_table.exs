defmodule RainerBlogBackend.Repo.Migrations.ModifyUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :id
      add :id, :uuid, primary_key: true
    end

    create unique_index(:users, [:name])
  end
end
