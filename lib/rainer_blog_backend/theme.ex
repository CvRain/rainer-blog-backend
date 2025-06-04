defmodule RainerBlogBackend.Theme do
  use Ecto.Schema
  import Ecto.Changeset
  alias RainerBlogBackend.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
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
    |> unique_constraint(:name)
  end

  @doc """
  获取主题列表，支持分页
  """
  def list_themes(page \\ 1, page_size \\ 10) do
    from(t in __MODULE__,
      order_by: [asc: t.order],
      limit: ^page_size,
      offset: ^((page - 1) * page_size)
    )
    |> Repo.all()
  end

  @doc """
  获取主题总数
  """
  def count_themes do
    Repo.aggregate(__MODULE__, :count)
  end

  @doc """
  根据ID获取主题
  """
  def get_theme(id) do
    Repo.get(__MODULE__, id)
  end

  @doc """
  创建主题
  """
  def create_theme(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  删除主题
  """
  def delete_theme(id) do
    case Repo.get(__MODULE__, id) do
      nil -> {:error, :not_found}
      theme -> Repo.delete(theme)
    end
  end
end
