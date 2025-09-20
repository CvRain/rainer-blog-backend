defmodule RainerBlogBackend.Collection do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias RainerBlogBackend.{Repo, Resource}

  @derive {Jason.Encoder, only: [:id, :name, :description, :order, :is_active, :inserted_at, :updated_at]}
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
    |> unique_constraint(:name)
  end

  @doc """
    获取存在的collection个数
  """
  @spec count() :: integer()
  def count() do
    Repo.aggregate(__MODULE__, :count, :id)
  end

  @doc """
    获取本周创建的collection个数
  """
  @spec count_append_weekly() :: integer()
  def count_append_weekly() do
    now = DateTime.utc_now()
    start_of_week = DateTime.add(now, -DateTime.to_unix(now) |> rem(7 * 24 * 60 * 60), :second)

    __MODULE__
    |> where([c], c.inserted_at >= ^start_of_week)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
    创建collection
  """
  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
    创建collection，包含默认值处理
  """
  @spec create_with_defaults(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_with_defaults(attrs) do
    # 检查必填字段
    case attrs["name"] do
      nil -> 
        # 创建一个带错误的changeset
        %__MODULE__{}
        |> changeset(attrs)
        |> Map.put(:valid?, false)
        |> Ecto.Changeset.add_error(:name, "can't be blank")
      
      "" -> 
        # 创建一个带错误的changeset
        %__MODULE__{}
        |> changeset(attrs)
        |> Map.put(:valid?, false)
        |> Ecto.Changeset.add_error(:name, "can't be blank")
      
      _ ->
        # 为可选字段设置默认值
        attrs_with_defaults = %{
          "name" => attrs["name"],
          "description" => Map.get(attrs, "description", ""),
          "is_active" => Map.get(attrs, "is_active", true),
          "order" => Map.get(attrs, "order", 0)
        }
        
        %__MODULE__{}
        |> changeset(attrs_with_defaults)
        |> Repo.insert()
    end
  end

  @doc """
    获取所有collection
  """
  def list_collections() do
    Repo.all(__MODULE__)
  end

  def list_active_collections() do
    __MODULE__
    |> where([c], c.is_active == true)
    |> Repo.all()
  end

  @doc """
    根据ID获取collection
  """
  def get_collection(id) do
    Repo.get(__MODULE__, id)
  end

  @doc """
    更新collection
  """
  def update_collection(%__MODULE__{} = collection, attrs) do
    collection
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
    删除collection及其中的所有resource
  """
  def delete_collection(%__MODULE__{} = collection) do
    # 开始数据库事务
    Repo.transaction(fn ->
      # 先删除该collection下的所有resource
      from(r in Resource, where: r.collection_id == ^collection.id)
      |> Repo.all()
      |> Enum.each(fn resource ->
        Resource.delete_resource(resource)
      end)

      # 然后删除collection本身
      case Repo.delete(collection) do
        {:ok, collection} -> collection
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end
end
