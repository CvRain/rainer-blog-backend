defmodule RainerBlogBackendWeb.Router do
  use RainerBlogBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug RainerBlogBackendWeb.AuthPlug
  end

  scope "/", RainerBlogBackendWeb do
    pipe_through :api

    get "/", OtherPageController, :main
  end

  scope "/api", RainerBlogBackendWeb do
    pipe_through :api

    get "/total/overview", OtherPageController, :storage_overview
  end

  scope "/api/user", RainerBlogBackendWeb do
    pipe_through :api

    get "/", UserController, :show
    post "/login", UserController, :login
    get "/verify", UserController, :verify_token
  end

  scope "/api/user", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

    patch "/", UserController, :update
  end

  scope "/api/article", RainerBlogBackendWeb do
    pipe_through :api

    get "/count", ArticleController, :count
    get "/count/this_week", ArticleController, :count_append_weekly
    post "/one", ArticleController, :create
    get "/one/:id", ArticleController, :show
    delete "/one/:id", ArticleController, :delete
    patch "/one/:id", ArticleController, :update
    get "/public_list", ArticleController, :public_list
  end

  scope "/api/article", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

    get "/list", ArticleController, :list
  end

  scope "/api/chapter", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

    post "/", ChapterController, :create
    put "/:id", ChapterController, :update
    delete "/:id", ChapterController, :delete
  end

  scope "/api/chapter", RainerBlogBackendWeb do
    pipe_through :api

    get "/", ChapterController, :index
    get "/active", ChapterController, :active
    get "/theme/:theme_id", ChapterController, :by_theme
    get "/theme/:theme_id/active", ChapterController, :active_by_theme
  end

  scope "/api/collection", RainerBlogBackendWeb do
    pipe_through :api

    get "/count", CollectionController, :count
    get "/count/this_week", CollectionController, :count_append_weekly
  end

  # todo
  scope "/api/collection", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

    post "/one", CollectionController, :create
    put "/:id", CollectionController, :update
    delete "/:id", CollectionController, :delete
  end


  scope "/api/resource", RainerBlogBackendWeb do
    pipe_through [:api]

    get "/count", ResourceController, :count
    get "/count/this_week", ResourceController, :count_append_weekly
  end

  scope "/api/resource", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

  end

  scope "/api/theme", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

    post "/one", ThemeController, :create
    patch "/one", ThemeController, :update
    delete "/:id", ThemeController, :remove
  end

  scope "/api/theme", RainerBlogBackendWeb do
    pipe_through [:api]

    get "/", ThemeController, :index
    get "/all", ThemeController, :all_themes
    get "/all/with_stats", ThemeController, :all_themes_with_stats
    get "/all/with_details", ThemeController, :all_themes_with_details
    get "/activite", ThemeController, :activite_themes
    get "/one/:id", ThemeController, :one_theme
    get "/one/:id/with_details", ThemeController, :one_theme_with_details
    get "/count", ThemeController, :count
    get "/count/this_week", ThemeController, :count_append_weekly

  end

  scope "/api/s3", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

    post "/config", S3Controller, :update_config
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

      live_dashboard "/dashboard", metrics: RainerBlogBackendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
