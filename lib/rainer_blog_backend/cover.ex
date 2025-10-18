defmodule RainerBlogBackend.Cover do
  @moduledoc """
  封面模型，用于为 theme/chapter/article 绑定 resource 作为封面。
  owner_type: "theme" | "chapter" | "article"
  owner_id: 对应 owner 的 uuid
  resource_id: 指向 resources 表的外键
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias RainerBlogBackend.{Repo, Resource, AwsService}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "covers" do
    field :owner_type, :string
    field :owner_id, :binary_id
    field :resource_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @required [:owner_type, :owner_id, :resource_id]

  def changeset(cover, attrs) do
    cover
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_inclusion(:owner_type, ["theme", "chapter", "article"])
    |> unique_constraint([:owner_type, :owner_id], name: :covers_owner_type_owner_id_index)
  end

  @doc "根据 owner_type 和 owner_id 获取封面记录"
  def get_by_owner(owner_type, owner_id) do
    from(c in __MODULE__, where: c.owner_type == ^owner_type and c.owner_id == ^owner_id)
    |> Repo.one()
  end

  @doc "为 owner 创建/更新封面（resource_id 必须存在）"
  def set_cover(owner_type, owner_id, resource_id) do
    attrs = %{owner_type: owner_type, owner_id: owner_id, resource_id: resource_id}

    case get_by_owner(owner_type, owner_id) do
      nil ->
        %__MODULE__{}
        |> changeset(attrs)
        |> Repo.insert()

      cover ->
        cover
        |> changeset(attrs)
        |> Repo.update()
    end
  end

  @doc "删除指定 owner 的封面（同时不删除 resource）"
  def delete_by_owner(owner_type, owner_id) do
    case get_by_owner(owner_type, owner_id) do
      nil -> {:ok, nil}
      cover -> Repo.delete(cover)
    end
  end

  @doc "返回 owner 对应封面资源的 presigned url（如果存在）"
  def get_presigned_url_by_owner(owner_type, owner_id, expires_in \\ 3600) do
    case get_by_owner(owner_type, owner_id) do
      nil -> {:error, :not_found}

      %__MODULE__{resource_id: resource_id} ->
        case Resource.get_resource(resource_id) do
          nil -> {:error, :resource_not_found}

          resource ->
            AwsService.generate_presigned_url(resource.aws_key, expires_in)
        end
    end
  end
end
