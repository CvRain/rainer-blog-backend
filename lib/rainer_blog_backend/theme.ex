defmodule RainerBlogBackend.Theme do
  use Ecto.Schema
  import Ecto.Changeset
  alias RainerBlogBackend.Repo

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
    |> unique_constraint(:name)
  end

  @doc """
  创建一个新的Theme, 并且返回新的Theme结构
  """
  @spec create(String.t(), String.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(name, description) do
    %RainerBlogBackend.Theme{}
    |> RainerBlogBackend.Theme.changeset(%{name: name, description: description})
    |> Repo.insert()
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
    获得存在的Theme的个数
  """
  @spec get_count() :: integer()
  def get_count() do
    Repo.aggregate(RainerBlogBackend.Theme, :count, :id)
  end
end
