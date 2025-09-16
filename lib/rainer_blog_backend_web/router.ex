defmodule RainerBlogBackendWeb.Router do
  use RainerBlogBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug RainerBlogBackendWeb.AuthPlug
  end

  # 首页
  scope "/", RainerBlogBackendWeb do
    pipe_through :api
    # 主页
    get "/", OtherPageController, :main
  end

  # 系统总览
  scope "/api", RainerBlogBackendWeb do
    pipe_through :api
    # 获取系统总览信息
    get "/total/overview", OtherPageController, :storage_overview
  end

  # 用户相关接口
  scope "/api/user", RainerBlogBackendWeb do
    pipe_through :api
    # 获取用户信息
    get "/", UserController, :show
    # 用户登录
    post "/login", UserController, :login
    # 校验token
    get "/verify", UserController, :verify_token
  end

  scope "/api/user", RainerBlogBackendWeb do
    pipe_through [:api, :auth]
    # 更新用户信息
    patch "/", UserController, :update
  end

  # 文章相关接口
  scope "/api/article", RainerBlogBackendWeb do
    pipe_through :api
    # 获取文章总数
    get "/count", ArticleController, :count
    # 获取本周新增文章数
    get "/count/this_week", ArticleController, :count_this_week
    # 创建文章
    post "/one", ArticleController, :create
    # 获取单篇文章详情
    get "/one/:id", ArticleController, :show
    # 删除文章
    delete "/one/:id", ArticleController, :delete
    # 更新文章
    patch "/one", ArticleController, :update
    # 获取公开文章列表（is_active=true）
    get "/public_list", ArticleController, :public_list
  end

  scope "/api/article", RainerBlogBackendWeb do
    pipe_through [:api, :auth]
    # 获取所有文章列表（需登录）
    get "/list", ArticleController, :list
  end

  # 章节相关接口
  scope "/api/chapter", RainerBlogBackendWeb do
    pipe_through [:api, :auth]
    # 创建章节
    post "/one", ChapterController, :create
    # 更新章节
    patch "/one", ChapterController, :update
    # 删除章节
    delete "/:id", ChapterController, :delete
  end

  scope "/api/chapter", RainerBlogBackendWeb do
    pipe_through :api
    # 获取章节列表（分页）
    get "/", ChapterController, :index
    # 获取激活章节列表（分页）
    get "/active", ChapterController, :active
    # 获取指定主题下所有章节
    get "/theme/:theme_id", ChapterController, :by_theme
    # 获取指定主题下激活章节
    get "/theme/:theme_id/active", ChapterController, :active_by_theme
  end

  # 收藏集相关接口
  scope "/api/collection", RainerBlogBackendWeb do
    pipe_through :api
    # 获取收藏集总数
    get "/count", CollectionController, :count
    # 获取本周新增收藏集数
    get "/count/this_week", CollectionController, :count_append_weekly
  end

  scope "/api/collection", RainerBlogBackendWeb do
    pipe_through [:api, :auth]
    # 收藏集 CRUD 接口
    resources "/", CollectionController, except: [:new, :edit]
  end

  # 资源相关接口
  scope "/api/resource", RainerBlogBackendWeb do
    pipe_through [:api]
    # 获取资源总数
    get "/count", ResourceController, :count
    # 获取本周新增资源数
    get "/count/this_week", ResourceController, :count_append_weekly
  end

  scope "/api/resource", RainerBlogBackendWeb do
    pipe_through [:api, :auth]
    # 预留资源管理接口
    resources "/", ResourceController, except: [:new, :edit]
    # 上传资源文件
    post "/upload", ResourceController, :upload
    # 下载资源文件
    get "/download/:id", ResourceController, :download
  end

  # 主题相关接口
  scope "/api/theme", RainerBlogBackendWeb do
    pipe_through [:api, :auth]
    # 创建主题
    post "/one", ThemeController, :create
    # 更新主题
    patch "/one", ThemeController, :update
    # 删除主题
    delete "/:id", ThemeController, :remove
    # 获取所有主题
    get "/all", ThemeController, :all_themes
    # 获取所有主题及统计
    get "/all/with_stats", ThemeController, :all_themes_with_stats
    # 获取所有主题及详细信息
    get "/all/with_details", ThemeController, :all_themes_with_details
  end

  scope "/api/theme", RainerBlogBackendWeb do
    pipe_through [:api]
    # 获取指定主题下激活内容（theme/chapter/article 均 is_active）
    get "/active_details/:id", ThemeController, :public_active_details
    # 获取主题列表
    get "/", ThemeController, :index
    # 获取激活主题列表
    get "/active", ThemeController, :active_themes
    # 获取单个主题详情
    get "/one/:id", ThemeController, :one_theme
    # 获取单个主题及详细信息
    get "/one/:id/with_details", ThemeController, :one_theme_with_details
    # 获取主题总数
    get "/count", ThemeController, :count
    # 获取本周新增主题数
    get "/count/this_week", ThemeController, :count_append_weekly
  end

  # S3 配置相关接口
  scope "/api/s3", RainerBlogBackendWeb do
    pipe_through [:api, :auth]
    # 更新 S3 配置
    post "/config", S3Controller, :update_config
    # 获取 S3 配置
    get "/config", S3Controller, :get_config
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:rainer_blog_backend, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      # 后台监控面板
      live_dashboard "/dashboard", metrics: RainerBlogBackendWeb.Telemetry
      # 邮箱预览
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
