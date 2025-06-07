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
    case CubDB.start_link(data_dir: @db_path, auto_compact: true) do
      {:ok, db} ->
        Logger.info("ConfigStore started with database at #{@db_path}")
        {:ok, %{db: db}}
      {:error, reason} ->
        Logger.error("Failed to start ConfigStore: #{inspect(reason)}")
        {:stop, reason}
    end
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
    case CubDB.get(db, key) do
      nil -> {:reply, {:error, :not_found}, state}
      value -> {:reply, {:ok, value}, state}
    end
  end

  def handle_call({:put, key, value}, _from, %{db: db} = state) do
    case CubDB.put(db, key, value) do
      :ok -> {:reply, {:ok, value}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:delete, key}, _from, %{db: db} = state) do
    case CubDB.delete(db, key) do
      :ok -> {:reply, :ok, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end
end
