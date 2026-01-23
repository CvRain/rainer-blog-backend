defmodule RainerBlogBackend.Repo.Migrations.RenameArticleContentToSubtitle do
  use Ecto.Migration

  def change do
    rename table(:articles), :content, to: :subtitle
  end
end
