defmodule RainerBlogBackend.ArticleContentCache do
  @moduledoc """
  文章内容缓存模块
  用于缓存从S3获取的文章内容，减少对S3的直接请求

  ## 缓存策略
  - TTL（Time To Live）：基于时间的过期策略
  - Content Hash：基于内容的变更检测
  - Stale-While-Revalidate：在后台刷新时返回过期缓存
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  alias RainerBlogBackend.{Repo, Article, AwsService}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "article_content_cache" do
    field :content, :string
    field :last_updated, :utc_datetime
    field :cached_at, :utc_datetime
    field :content_hash, :string
    field :expires_at, :utc_datetime
    belongs_to :article, Article, type: :binary_id

    timestamps()
  end

  # 配置项
  # 默认1天
  @ttl_seconds Application.compile_env(:rainer_blog_backend, :content_cache_ttl, 86_400)
  # 默认7天
  @stale_max_seconds Application.compile_env(:rainer_blog_backend, :content_stale_max, 604_800)
  @refresh_enabled Application.compile_env(
                     :rainer_blog_backend,
                     :content_cache_refresh_enabled,
                     true
                   )

  @doc false
  def changeset(cache, attrs) do
    cache
    |> cast(attrs, [:article_id, :content, :last_updated, :cached_at, :content_hash, :expires_at])
    |> validate_required([:article_id, :content, :last_updated])
  end

  @doc """
  计算内容的 MD5 hash
  """
  def compute_hash(content) when is_binary(content) do
    :crypto.hash(:md5, content) |> Base.encode16(case: :lower)
  end

  @doc """
  根据文章ID获取缓存的内容
  """
  def get_by_article_id(article_id) do
    Repo.one(from c in __MODULE__, where: c.article_id == ^article_id)
  end

  @doc """
  获取或刷新缓存内容（支持 TTL 和 stale-while-revalidate）

  返回值：
  - `{:ok, content}` - 有效缓存内容
  - `{:stale, content}` - 过期但可用的内容（同时触发后台刷新）
  - `{:error, reason}` - 获取失败

  ## 策略
  1. 缓存未过期 (age < TTL)：直接返回
  2. 缓存已过期但在 stale window 内：返回 stale 内容并异步刷新
  3. 缓存过期超过 stale max：同步刷新或返回错误
  """
  def get_or_refresh(article_id, aws_key) do
    now = DateTime.utc_now()

    case get_by_article_id(article_id) do
      nil ->
        # 无缓存，直接从 S3 获取
        Logger.info("Cache miss for article #{article_id}, fetching from S3")
        fetch_and_store(article_id, aws_key, now)

      %__MODULE__{content: content, cached_at: cached_at} ->
        age_seconds =
          if cached_at, do: DateTime.diff(now, cached_at, :second), else: @stale_max_seconds + 1

        cond do
          # Fast path: 缓存未过期
          age_seconds < @ttl_seconds ->
            Logger.debug("Cache hit for article #{article_id}, age: #{age_seconds}s")
            {:ok, content}

          # Stale-while-revalidate: 返回过期内容，后台刷新
          age_seconds < @stale_max_seconds and @refresh_enabled ->
            Logger.info(
              "Cache stale for article #{article_id}, age: #{age_seconds}s, triggering async refresh"
            )

            # 异步刷新
            Task.start(fn ->
              fetch_and_store(article_id, aws_key, DateTime.utc_now())
            end)

            {:stale, content}

          # 缓存太旧或刷新已禁用，尝试同步刷新
          true ->
            Logger.warning(
              "Cache expired for article #{article_id}, age: #{age_seconds}s, attempting sync refresh"
            )

            case fetch_and_store(article_id, aws_key, now) do
              {:ok, new_content} ->
                {:ok, new_content}

              {:error, reason} ->
                # S3 失败，如果缓存还在 stale max 内，返回 stale
                if age_seconds < @stale_max_seconds do
                  Logger.warning(
                    "S3 fetch failed for article #{article_id}, returning stale cache: #{inspect(reason)}"
                  )

                  {:stale, content}
                else
                  Logger.error(
                    "S3 fetch failed and cache too old for article #{article_id}: #{inspect(reason)}"
                  )

                  {:error, reason}
                end
            end
        end
    end
  end

  # 从 S3 获取内容并存储到缓存
  defp fetch_and_store(article_id, aws_key, now) do
    case AwsService.download_content(aws_key) do
      {:ok, content} ->
        hash = compute_hash(content)

        attrs = %{
          article_id: article_id,
          content: content,
          content_hash: hash,
          cached_at: now,
          last_updated: now,
          expires_at: DateTime.add(now, @ttl_seconds, :second)
        }

        case upsert_by_article_id(article_id, attrs) do
          {:ok, _cache} ->
            Logger.info("Successfully cached content for article #{article_id}, hash: #{hash}")
            {:ok, content}

          {:error, changeset} ->
            Logger.error(
              "Failed to cache content for article #{article_id}: #{inspect(changeset.errors)}"
            )

            {:error, :cache_write_failed}
        end

      {:error, reason} = error ->
        Logger.error("Failed to fetch from S3 for article #{article_id}: #{inspect(reason)}")
        error
    end
  end

  # 根据 article_id upsert 缓存记录
  defp upsert_by_article_id(article_id, attrs) do
    case get_by_article_id(article_id) do
      nil ->
        %__MODULE__{}
        |> changeset(attrs)
        |> Repo.insert()

      cache ->
        cache
        |> changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  创建或更新文章内容缓存（手动）
  @deprecated 请使用 get_or_refresh 自动管理缓存
  """
  def upsert_content(article_id, content) do
    now = DateTime.utc_now()
    hash = compute_hash(content)

    attrs = %{
      article_id: article_id,
      content: content,
      content_hash: hash,
      cached_at: now,
      last_updated: now,
      expires_at: DateTime.add(now, @ttl_seconds, :second)
    }

    upsert_by_article_id(article_id, attrs)
  end

  @doc """
  删除指定文章的缓存
  """
  def delete_by_article_id(article_id) do
    case get_by_article_id(article_id) do
      nil -> {:ok, nil}
      cache -> Repo.delete(cache)
    end
  end

  @doc """
  获取所有过期的缓存记录（用于后台刷新任务）
  """
  def list_expired_caches(limit \\ 50) do
    now = DateTime.utc_now()

    from(c in __MODULE__,
      where: c.expires_at < ^now or is_nil(c.expires_at),
      limit: ^limit,
      order_by: [asc: c.expires_at]
    )
    |> Repo.all()
  end

  @doc """
  获取缓存统计信息
  """
  def get_stats do
    now = DateTime.utc_now()
    # "valid" 即 expires_at >= now
    valid_threshold = now
    # "stale" 即 expires_at < now 但在保留期内
    # 保留期是 stale_max_seconds (比如7天)
    # expires_at = cached_at + ttl
    # cached_at >= now - stale_max
    # cached_at + ttl >= now - stale_max + ttl
    # expires_at >= now - (stale_max - ttl)
    stale_threshold = DateTime.add(now, -(@stale_max_seconds - @ttl_seconds), :second)

    total = Repo.aggregate(__MODULE__, :count, :id)

    valid =
      from(c in __MODULE__, where: c.expires_at >= ^valid_threshold)
      |> Repo.aggregate(:count, :id)

    stale =
      from(c in __MODULE__,
        where: c.expires_at < ^valid_threshold and c.expires_at >= ^stale_threshold
      )
      |> Repo.aggregate(:count, :id)

    expired =
      from(c in __MODULE__, where: c.expires_at < ^stale_threshold or is_nil(c.expires_at))
      |> Repo.aggregate(:count, :id)

    %{
      total: total,
      valid: valid,
      stale: stale,
      expired: expired,
      ttl_seconds: @ttl_seconds,
      stale_max_seconds: @stale_max_seconds
    }
  end
end
