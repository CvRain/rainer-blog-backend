defmodule RainerBlogBackend.Repo do
  use Ecto.Repo,
    otp_app: :rainer_blog_backend,
    adapter: Ecto.Adapters.Postgres
end
