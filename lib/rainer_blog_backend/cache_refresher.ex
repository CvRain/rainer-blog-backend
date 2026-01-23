defmodule RainerBlogBackend.CacheRefresher do
  @moduledoc """
  后台缓存刷新服务

  定期扫描过期的文章内容缓存并异步刷新，以保持缓存的新鲜度。

  ## 功能
  - 定期扫描过期缓存
  - 批量异步刷新
  - 并发控制（防止 S3 请求风暴）
  - 统计指标记录
  """

  use GenServer
  require Logger

  alias RainerBlogBackend.{ArticleContentCache, Article, Repo}

  # 默认5分钟
  @interval_ms Application.compile_env(:rainer_blog_backend, :cache_refresher_interval, 300_000)
  @batch_size Application.compile_env(:rainer_blog_backend, :cache_refresher_batch, 20)
  @max_concurrent Application.compile_env(
                    :rainer_blog_backend,
                    :cache_refresher_max_concurrent,
                    5
                  )

  defmodule State do
    defstruct [
      :refresh_count,
      :error_count,
      :last_run_at,
      :running_tasks
    ]
  end

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  手动触发一次刷新
  """
  def trigger_refresh do
    GenServer.cast(__MODULE__, :refresh_now)
  end

  @doc """
  获取刷新器状态
  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Process.flag(:trap_exit, true)

    Logger.info(
      "CacheRefresher starting with interval #{@interval_ms}ms, batch size #{@batch_size}"
    )

    # 启动后稍等片刻再开始第一次刷新
    Process.send_after(self(), :refresh, 10_000)

    {:ok,
     %State{
       refresh_count: 0,
       error_count: 0,
       last_run_at: nil,
       running_tasks: MapSet.new()
     }}
  end

  @impl true
  def handle_info(:refresh, state) do
    new_state = perform_refresh(state)

    # 安排下次刷新
    Process.send_after(self(), :refresh, @interval_ms)

    {:noreply, new_state}
  end

  @impl true
  def handle_info({ref, result}, state) when is_reference(ref) do
    # Task 完成消息：{ref, result}
    # 清理任务引用
    Process.demonitor(ref, [:flush])
    new_tasks = MapSet.delete(state.running_tasks, ref)

    new_state =
      case result do
        {:ok, _} ->
          %{state | refresh_count: state.refresh_count + 1, running_tasks: new_tasks}

        {:deleted, _} ->
          %{state | refresh_count: state.refresh_count + 1, running_tasks: new_tasks}

        {:error, reason} ->
          Logger.warning("Cache refresh task failed: #{inspect(reason)}")
          %{state | error_count: state.error_count + 1, running_tasks: new_tasks}
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    # 清理已完成的任务引用
    {:noreply, %{state | running_tasks: MapSet.delete(state.running_tasks, ref)}}
  end

  @impl true
  def handle_cast(:refresh_now, state) do
    new_state = perform_refresh(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    stats = ArticleContentCache.get_stats()

    response = %{
      refresh_count: state.refresh_count,
      error_count: state.error_count,
      last_run_at: state.last_run_at,
      running_tasks: MapSet.size(state.running_tasks),
      cache_stats: stats
    }

    {:reply, response, state}
  end

  # Private Functions

  defp perform_refresh(state) do
    now = DateTime.utc_now()
    Logger.info("Starting cache refresh cycle at #{now}")

    # 如果已经有太多任务在运行，跳过这次刷新
    if MapSet.size(state.running_tasks) >= @max_concurrent do
      Logger.warning(
        "Too many concurrent refresh tasks (#{MapSet.size(state.running_tasks)}), skipping this cycle"
      )

      state
    else
      expired_caches = ArticleContentCache.list_expired_caches(@batch_size)

      Logger.info("Found #{length(expired_caches)} expired caches to refresh")

      # 为每个过期缓存启动异步刷新任务
      new_tasks =
        Enum.reduce(expired_caches, state.running_tasks, fn cache, tasks ->
          if MapSet.size(tasks) < @max_concurrent do
            spawn_refresh_task(cache, tasks)
          else
            tasks
          end
        end)

      %{state | last_run_at: now, running_tasks: new_tasks}
    end
  end

  defp spawn_refresh_task(cache, current_tasks) do
    task =
      Task.async(fn ->
        # 获取文章的 aws_key
        case Repo.get(Article, cache.article_id) do
          nil ->
            Logger.warning("Article #{cache.article_id} not found, deleting cache")
            ArticleContentCache.delete_by_article_id(cache.article_id)
            {:deleted, cache.article_id}

          article ->
            Logger.debug("Refreshing cache for article #{article.id}")

            case ArticleContentCache.get_or_refresh(article.id, article.aws_key) do
              {:ok, _content} ->
                Logger.debug("Successfully refreshed cache for article #{article.id}")
                {:ok, article.id}

              {:stale, _content} ->
                # Stale 也算成功，因为内容已经可用
                Logger.debug("Got stale content for article #{article.id}")
                {:ok, article.id}

              {:error, reason} = error ->
                Logger.warning(
                  "Failed to refresh cache for article #{article.id}: #{inspect(reason)}"
                )

                error
            end
        end
      end)

    MapSet.put(current_tasks, task.ref)
  end
end
