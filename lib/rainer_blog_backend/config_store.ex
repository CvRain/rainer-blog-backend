defmodule RainerBlogBackend.ConfigStore do
  use GenServer
  require Logger

  @db_path "priv/cubdb/user_config"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    # 确保目录存在
    File.mkdir_p!(Path.dirname(@db_path))

    # 启动 CubDB
    {:ok, db} = CubDB.start_link(data_dir: @db_path, auto_compact: true)

    Logger.info("ConfigStore started with database at #{@db_path}")
    {:ok, %{db: db}}
  end

  # 客户端 API

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  # 服务器回调

  def handle_call({:get, key}, _from, %{db: db} = state) do
    value = CubDB.get(db, key)
    {:reply, value, state}
  end

  def handle_call({:put, key, value}, _from, %{db: db} = state) do
    :ok = CubDB.put(db, key, value)
    {:reply, :ok, state}
  end

  def handle_call({:delete, key}, _from, %{db: db} = state) do
    :ok = CubDB.delete(db, key)
    {:reply, :ok, state}
  end
end
