defmodule RainerBlogBackend.Theme do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias RainerBlogBackend.Repo
  alias RainerBlogBackend.Chapter

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [:id, :name, :description, :order, :is_active, :inserted_at, :updated_at]}
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
    |> validate_format(:name, ~r/^[\p{Han}a-zA-Z0-9_]+$/u, message: "主题名称只能包含中文、字母、数字和下划线")
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
  @spec update(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update(attrs) do
    case get_one(attrs.id) do
      nil ->
        {:error, "主题不存在"}
      theme ->
        theme
        |> changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  获得所有的Theme数量
  """
  @spec count() :: integer()
  def count() do
    Repo.aggregate(RainerBlogBackend.Theme, :count, :id)
  end

  @doc """
  获得本周创建的Theme数量
  """
  @spec count_append_weekly() :: integer()
  def count_append_weekly() do
    now = DateTime.utc_now()
    start_of_week = DateTime.add(now, -DateTime.to_unix(now) |> rem(7 * 24 * 60 * 60), :second)

    __MODULE__
    |> where([t], t.inserted_at >= ^start_of_week)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  获取所有主题及其下章节数和文章数统计
  """
  def get_all_with_stats() do
    themes = Repo.all(__MODULE__)

    Enum.map(themes, fn theme ->
      chapter_count =
        RainerBlogBackend.Chapter
        |> where([c], c.theme_id == ^theme.id)
        |> Repo.aggregate(:count, :id)

      article_count =
        from(a in RainerBlogBackend.Article,
          join: c in RainerBlogBackend.Chapter,
          on: a.chapter_id == c.id,
          where: c.theme_id == ^theme.id,
          select: count(a.id)
        )
        |> Repo.one()

      theme_map = Map.from_struct(theme) |> Map.drop([:__meta__, :__struct__])

      theme_map
      |> Map.put(:chapter_count, chapter_count)
      |> Map.put(:article_count, article_count)
    end)
  end
end
