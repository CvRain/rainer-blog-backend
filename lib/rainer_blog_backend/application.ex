defmodule RainerBlogBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias RainerBlogBackend.AwsService

  @impl true
  def start(_type, _args) do
    # Initialize AWS configuration
    AwsService.init_config()

    children = [
      RainerBlogBackendWeb.Telemetry,
      RainerBlogBackend.Repo,
      {DNSCluster,
       query: Application.get_env(:rainer_blog_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RainerBlogBackend.PubSub},
      {Finch, name: RainerBlogBackend.Finch},
      RainerBlogBackend.UserConfig,
      RainerBlogBackendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RainerBlogBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RainerBlogBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
