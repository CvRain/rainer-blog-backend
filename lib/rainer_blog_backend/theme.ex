defmodule RainerBlogBackend.Theme do
  use Ecto.Schema
  import Ecto.Changeset
  alias RainerBlogBackend.Repo
  alias RainerBlogBackend.Chapter

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:id, :name, :description, :order, :is_active, :inserted_at, :updated_at]}
  schema "themes" do
    field :name, :string
    field :description, :string
    field :order, :integer
    field :is_active, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false

  def changeset(theme, attrs) do
    theme
    |> cast(attrs, [:name, :description, :order, :is_active])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[a-zA-Z0-9_-]+$/, message: "主题名称只能包含字母、数字、下划线和减号")
    |> unique_constraint(:name)
  end

  @doc """
  创建一个新的Theme, 并且返回新的Theme结构
  同时会创建一个默认(.default)的chapter
  """
  @spec create(String.t(), String.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(name, description) do
    Repo.transaction(fn ->
      case %RainerBlogBackend.Theme{}
           |> RainerBlogBackend.Theme.changeset(%{name: name, description: description})
           |> Repo.insert() do
        {:ok, theme} ->
          # 创建默认chapter
          case Chapter.create(%{
                 name: ".default",
                 description: "默认章节",
                 order: 0,
                 is_active: true,
                 theme_id: theme.id
               }) do
            {:ok, _chapter} -> theme
            {:error, _} -> Repo.rollback("Failed to create default chapter")
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  通过id删除一个Theme
  """
  @spec remove(String.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def remove(id) do
    Repo.get(RainerBlogBackend.Theme, id)
    |> Repo.delete()
  end

  @doc """
  通过id获得一个Theme
  """
  @spec get_one(String.t()) :: Ecto.Schema.t() | nil
  def get_one(id) do
    Repo.get(RainerBlogBackend.Theme, id)
  end

  @doc """
  获得所有的Theme
  """
  @spec get_all() :: [Ecto.Schema.t() | term()]
  def get_all() do
    Repo.all(RainerBlogBackend.Theme)
  end

  @doc """
  更新一个Theme
  """
  @spec update(Ecto.Schema.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update(theme) do
    Repo.update(theme)
  end

  @doc """
  获得所有的Theme数量
  """
  @spec count() :: integer()
  def count() do
    Repo.aggregate(RainerBlogBackend.Theme, :count, :id)
  end
end
