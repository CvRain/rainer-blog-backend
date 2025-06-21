defmodule RainerBlogBackend.Chapter do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias RainerBlogBackend.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:id, :name, :description, :order, :is_active, :theme_id, :inserted_at, :updated_at]}
  schema "chapters" do
    field :name, :string
    field :description, :string
    field :order, :integer
    field :is_active, :boolean, default: false
    field :theme_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chapter, attrs) do
    chapter
    |> cast(attrs, [:name, :description, :order, :is_active, :theme_id])
    |> validate_required([:name, :theme_id])
    |> unique_constraint([:name, :theme_id])
  end

  @doc """
  创建一个新的Chapter
  """
  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  获取所有Chapter，支持分页
  """
  @spec get_all(integer(), integer()) :: [Ecto.Schema.t()]
  def get_all(page \\ 1, page_size \\ 10) do
    offset = (page - 1) * page_size

    __MODULE__
    |> order_by([c], asc: c.order)
    |> offset(^offset)
    |> limit(^page_size)
    |> Repo.all()
  end

  @doc """
  获取所有激活的Chapter，支持分页
  """
  @spec get_active(integer(), integer()) :: [Ecto.Schema.t()]
  def get_active(page \\ 1, page_size \\ 10) do
    offset = (page - 1) * page_size

    __MODULE__
    |> where([c], c.is_active == true)
    |> order_by([c], asc: c.order)
    |> offset(^offset)
    |> limit(^page_size)
    |> Repo.all()
  end

  @doc """
  获取指定theme下的所有Chapter
  """
  @spec get_by_theme(String.t(), integer(), integer()) :: [Ecto.Schema.t()]
  def get_by_theme(theme_id, page \\ 1, page_size \\ 10) do
    offset = (page - 1) * page_size

    __MODULE__
    |> where([c], c.theme_id == ^theme_id)
    |> order_by([c], asc: c.order)
    |> offset(^offset)
    |> limit(^page_size)
    |> Repo.all()
  end

  @doc """
  获取指定theme下激活的Chapter
  """
  @spec get_active_by_theme(String.t(), integer(), integer()) :: [Ecto.Schema.t()]
  def get_active_by_theme(theme_id, page \\ 1, page_size \\ 10) do
    offset = (page - 1) * page_size

    __MODULE__
    |> where([c], c.theme_id == ^theme_id and c.is_active == true)
    |> order_by([c], asc: c.order)
    |> offset(^offset)
    |> limit(^page_size)
    |> Repo.all()
  end

  @doc """
  删除指定的Chapter
  """
  @spec delete(String.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def delete(id) do
    Repo.get(__MODULE__, id)
    |> Repo.delete()
  end

  @doc """
  更新指定的Chapter
  """
  @spec update(String.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update(id, attrs) do
    Repo.get(__MODULE__, id)
    |> changeset(attrs)
    |> Repo.update()
  end
end
