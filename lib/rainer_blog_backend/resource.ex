defmodule RainerBlogBackend.Resource do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias RainerBlogBackend.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "resources" do
    field :name, :string
    field :description, :string
    field :file_type, :string
    field :file_size, :integer
    field :aws_key, :string
    field :order, :integer
    field :is_active, :boolean, default: false
    field :collection_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:name, :description, :file_type, :file_size, :aws_key, :order, :is_active, :collection_id])
    |> validate_required([:name, :description, :file_type, :file_size, :aws_key, :order, :is_active])
  end

   @doc """
    获取存在的resource个数
  """
  @spec count() :: integer()
  def count() do
    Repo.aggregate(RainerBlogBackend.Resource, :count, :id)
  end

  @doc """
    获取本周创建的resource个数
  """
  @spec count_append_weekly() :: integer()
  def count_append_weekly() do
    now = DateTime.utc_now()
    start_of_week = DateTime.add(now, -DateTime.to_unix(now) |> rem(7 * 24 * 60 * 60), :second)

    __MODULE__
    |> where([r], r.inserted_at >= ^start_of_week)
    |> Repo.aggregate(:count, :id)
  end

  def list_resources() do
    Repo.all(__MODULE__)
  end

  def get_resource(id) do
    Repo.get(__MODULE__, id)
  end

  def create_resource(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def update_resource(%__MODULE__{} = resource, attrs) do
    resource
    |> changeset(attrs)
    |> Repo.update()
  end

  def delete_resource(%__MODULE__{} = resource) do
    # 先尝试删除S3文件
    _ = RainerBlogBackend.AwsService.delete_content(resource.aws_key)
    Repo.delete(resource)
  end
end