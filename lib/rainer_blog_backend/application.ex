defmodule RainerBlogBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RainerBlogBackendWeb.Telemetry,
      RainerBlogBackend.Repo,
      {DNSCluster, query: Application.get_env(:rainer_blog_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RainerBlogBackend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: RainerBlogBackend.Finch},
      # Start ConfigStore for user configurations
      RainerBlogBackend.ConfigStore,
      # Start a worker by calling: RainerBlogBackend.Worker.start_link(arg)
      # {RainerBlogBackend.Worker, arg},
      # Start to serve requests, typically the last entry
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
