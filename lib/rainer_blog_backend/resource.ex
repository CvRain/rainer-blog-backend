defmodule RainerBlogBackend.Resource do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias RainerBlogBackend.Repo

  @derive {Jason.Encoder, only: [:id, :name, :description, :file_type, :file_size, :aws_key, :order, :is_active, :collection_id, :inserted_at, :updated_at]}
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
    |> unique_constraint([:name, :collection_id], name: :resources_name_collection_id_index)
    |> unique_constraint(:aws_key)
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

  @doc """
    根据 aws_key 查找资源（用于检查是否已存在）
  """
  def get_by_aws_key(aws_key) do
    Repo.get_by(__MODULE__, aws_key: aws_key)
  end

  @doc """
    根据文件内容的 hash 查找资源（检查是否上传过相同内容的文件）
    这里我们使用 aws_key 作为唯一标识，因为 aws_key 包含了 UUID
    更好的方式是添加 file_hash 字段
  """
  def find_by_content_hash(content) do
    # 计算文件内容的 MD5 hash
    hash = :crypto.hash(:md5, content) |> Base.encode16(case: :lower)

    # 注意：这需要数据库中有 file_hash 字段
    # 目前我们先返回 nil，后续可以扩展
    nil
  end

  @doc """
    获取指定 collection 中的所有资源
  """
  def list_by_collection(collection_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 20)
    offset = (page - 1) * page_size

    query = from r in __MODULE__,
      where: r.collection_id == ^collection_id,
      order_by: [desc: r.inserted_at],
      limit: ^page_size,
      offset: ^offset

    Repo.all(query)
  end

  @doc """
    统计指定 collection 中的资源数量
  """
  def count_by_collection(collection_id) do
    from(r in __MODULE__, where: r.collection_id == ^collection_id)
    |> Repo.aggregate(:count, :id)
  end
end
