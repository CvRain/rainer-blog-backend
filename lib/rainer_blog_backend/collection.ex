defmodule RainerBlogBackend.Collection do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "collections" do
    field :name, :string
    field :description, :string
    field :order, :integer
    field :is_active, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name, :description, :order, :is_active])
    |> validate_required([:name, :description, :order, :is_active])
  end

  @doc """
    获取存在的collection个数
  """
  @spec count() :: integer()
  def count() do
    RainerBlogBackend.Repo.aggregate(RainerBlogBackend.Collection, :count, :id)
  end

  @doc """
    获取本周创建的collection个数
  """
  @spec count_append_weekly() :: integer()
  def count_append_weekly() do
    now = DateTime.utc_now()
    start_of_week = DateTime.add(now, -DateTime.to_unix(now) |> rem(7 * 24 * 60 * 60), :second)

    RainerBlogBackend.Collection
    |> where([c], c.inserted_at >= ^start_of_week)
    |> RainerBlogBackend.Repo.aggregate(:count, :id)
  end

  @doc """
    创建collection
  """
  @spec create(String.t(), String.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(name, description) do
    %RainerBlogBackend.Collection{
      name: name,
      description: description,
      order: 0,
      is_active: true
    }
    |> RainerBlogBackend.Repo.insert()
  end

  @doc """
    删除collection
  """
  def remove(id) do
    RainerBlogBackend.Repo.delete(id)
  end

  @doc """
    更新collection
  """
  def update(id, name, description) do
    RainerBlogBackend.Repo.update(id, name: name, description: description)
  end
end
