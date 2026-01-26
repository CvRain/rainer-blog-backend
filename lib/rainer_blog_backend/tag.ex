defmodule RainerBlogBackend.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias RainerBlogBackend.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:id, :name, :color, :slug]}

  schema "tags" do
    field :name, :string
    field :color, :string
    field :slug, :string

    many_to_many :articles, RainerBlogBackend.Article, join_through: "articles_tags"

    timestamps(type: :utc_datetime)
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :color, :slug])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def get_or_create_tags(names) when is_list(names) do
    names = Enum.uniq(names)

    # 1. Find existing tags
    existing_tags =
      from(t in __MODULE__, where: t.name in ^names)
      |> Repo.all()

    existing_names = Enum.map(existing_tags, & &1.name)

    # 2. Identify new tags
    new_names = names -- existing_names

    # 3. Create new tags
    new_tags =
      Enum.map(new_names, fn name ->
        {:ok, tag} =
          %__MODULE__{}
          |> changeset(%{name: name})
          |> Repo.insert()
        tag
      end)

    # 4. Return all tags
    existing_tags ++ new_tags
  end

  def get_or_create_tags(_), do: []
end
