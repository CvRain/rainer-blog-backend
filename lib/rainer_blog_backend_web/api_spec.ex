defmodule RainerBlogBackendWeb.ApiSpec do
  alias OpenApiSpex.{OpenApi, Server, Info, Paths}

  @behaviour OpenApiSpex.OpenApi

  @impl OpenApiSpex.OpenApi
  def spec do
    %OpenApi{
      servers: [
        # Populate the Server info from a config variable
        Server.from_endpoint(RainerBlogBackendWeb.Endpoint)
      ],
      info: %Info{
        title: "Rainer Blog Backend API",
        version: "1.0"
      },
      # Populate the paths from a phoenix router
      paths: Paths.from_router(RainerBlogBackendWeb.Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
