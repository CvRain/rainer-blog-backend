# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :rainer_blog_backend,
  ecto_repos: [RainerBlogBackend.Repo],
  generators: [timestamp_type: :utc_datetime],
  # Article content cache configuration
  content_cache_ttl: 86_400,  # 1 day in seconds
  content_stale_max: 604_800,  # 7 days in seconds (stale-while-revalidate window)
  content_cache_refresh_enabled: true,
  cache_refresher_interval: 300_000,  # 5 minutes in milliseconds
  cache_refresher_batch: 20,  # Refresh 20 expired caches per run
  cache_refresher_max_concurrent: 5  # Max 5 concurrent refresh tasks

# Configures the endpoint
config :rainer_blog_backend, RainerBlogBackendWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RainerBlogBackendWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: RainerBlogBackend.PubSub,
  live_view: [signing_salt: "YYAlqKLP"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :rainer_blog_backend, RainerBlogBackend.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

if System.get_env("PHX_SERVER") do
  config :rainer_blog_backend, RainerBlogBackendWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :rainer_blog_backend, RainerBlogBackend.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :rainer_blog_backend, RainerBlogBackendWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SSL_KEYFILE"),
  #         certfile: System.get_env("SSL_CERTFILE")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/bandit/Bandit.html#t:ssl_option/0

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :rainer_blog_backend, RainerBlogBackend.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :rainer_blog_backend, :auth,
    issuer: "rainer_blog_backend",
    secret_key: System.get_env("SECRET_KEY_BASE")

  config :rainer_blog_backend, RainerBlogBackendWeb.Endpoint,
    url: [host: System.get_env("APP_NAME") || "localhost", port: 80],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: System.get_env("SECRET_KEY_BASE")

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :rainer_blog_backend, RainerBlogBackend.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end

# Configure CORS
config :cors_plug,
  origin: [
    "http://localhost:4200",
    "http://localhost:4200",
    "http://ecs.cloudvl.cn",
    "http://cvrain.cloudvl.cn",
    "https://cvrain.cloudvl.cn",
    "https://ecs.cloudvl.cn"
    ],
  max_age: 86400,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  headers: [
    "Authorization",
    "Content-Type",
    "Accept",
    "Origin",
    "User-Agent",
    "DNT",
    "Cache-Control",
    "X-Mx-ReqToken",
    "Keep-Alive",
    "X-Requested-With",
    "If-Modified-Since",
    "X-CSRF-Token"
  ]

config :ex_aws, :s3,
  scheme: "https://",
  host: "obs.cn-east-3.myhuaweicloud.com",
  region: "us-east-1"
