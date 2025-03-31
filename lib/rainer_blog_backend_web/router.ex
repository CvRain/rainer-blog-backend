defmodule RainerBlogBackendWeb.Router do
  alias Hex.API.User
  use RainerBlogBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end


  pipeline :auth do
    plug :api
  end

  scope "/api", RainerBlogBackendWeb do
    pipe_through :api

    get "/hello", HelloController, :hello
    get "/hello/echo", HelloController, :echo
    post "/hello/weather", HelloController, :add_weather
  end

  scope "/api", RainerBlogBackendWeb do
    pipe_through [:api, :auth]

  end

  scope "/api/user", RainerBlogBackendWeb do
    pipe_through :api

    post "/auth/login", UserController, :login
    post "/auth/register", UserController, :register
    get "/one", UserController, :show
    patch "/one", UserController, :update
    put "/one", UserController, :update
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
