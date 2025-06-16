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
  end

  scope "/api/theme", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

    post "/one", ThemeController, :create
    put "/:id", ThemeController, :update
    delete "/:id", ThemeController, :delete
  end

  scope "/api/theme", RainerBlogBackendWeb do
    pipe_through [:api]

    get "/", ThemeController, :index
    get "/all", ThemeController, :all_themes
    get "/activite", ThemeController, :activite_themes
    get "/one", ThemeController, :one_theme
    get "/count", ThemeController, :count
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
