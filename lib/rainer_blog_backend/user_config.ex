defmodule RainerBlogBackend.UserConfig do
  @moduledoc """
  管理系统配置，主要用于AWS配置存储
  用户信息已迁移到PostgreSQL数据库中
  """
  use GenServer
  require Logger

  @db_path "priv/cubdb/user_config"  # 保持使用原路径，AWS配置存储在这里
  @aws_config_key "aws_config"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, db} = CubDB.start_link(@db_path, auto_file_sync: true)
    {:ok, %{db: db}}
  end

  def get_aws_config do
    GenServer.call(__MODULE__, :get_aws_config)
  end

  def update_aws_config(config) do
    GenServer.call(__MODULE__, {:update_aws_config, config})
  end

  def handle_call(:get_aws_config, _from, %{db: db} = state) do
    config =
      CubDB.get(db, @aws_config_key) ||
        %{
          access_key_id: "",
          secret_access_key: "",
          region: "",
          bucket: ""
        }

    {:reply, config, state}
  end

  def handle_call({:update_aws_config, config}, _from, %{db: db} = state) do
    :ok = CubDB.put(db, @aws_config_key, config)
    {:reply, :ok, state}
  end
end
