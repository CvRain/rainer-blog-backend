defmodule RainerBlogBackend.Repo do
  use Ecto.Repo,
    otp_app: :rainer_blog_backend,
    adapter: Mongo.Ecto
end
