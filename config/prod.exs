import Config

# 强制 HTTPS，推荐生产环境开启
config :rainer_blog_backend, RainerBlogBackendWeb.Endpoint,
  force_ssl: [hsts: true],
  url: [host: System.get_env("PHX_HOST") || "example.com", port: 443, scheme: "https"]

# Logger 级别
config :logger, level: :info

# Swoosh 邮件适配器（如需其他服务请替换）
config :rainer_blog_backend, RainerBlogBackend.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN")

# Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: RainerBlogBackend.Finch

# 禁用 Swoosh 本地存储
config :swoosh, local: false

# 生产环境运行时配置请放在 config/runtime.exs
