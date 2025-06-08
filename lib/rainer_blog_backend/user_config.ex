defmodule RainerBlogBackend.UserConfig do
  use GenServer
  require Logger

  @db_path "priv/cubdb/user_config"
  @user_config_key "user_config"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, db} = CubDB.start_link(@db_path, auto_file_sync: true)
    {:ok, %{db: db}}
  end

  def get_user_config do
    GenServer.call(__MODULE__, :get_user_config)
  end

  def update_user_config(config) do
    GenServer.call(__MODULE__, {:update_user_config, config})
  end

  def handle_call(:get_user_config, _from, %{db: db} = state) do
    config = CubDB.get(db, @user_config_key) || %{
      user_name: "",
      user_email: "",
      user_password: "",
      user_signature: "",
      user_avatar: "",
      user_background: ""
    }
    {:reply, config, state}
  end

  def handle_call({:update_user_config, config}, _from, %{db: db} = state) do
    :ok = CubDB.put(db, @user_config_key, config)
    {:reply, :ok, state}
  end
end
