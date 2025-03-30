defmodule RainerBlogBackendWeb.HelloController do
  use RainerBlogBackendWeb, :controller

  def hello(conn, _params) do
    response = %{
      code: 200,
      message: "Hello World!",
      result: "200Ok",
      timestamp: DateTime.utc_now()
    }

    json(conn, response)
  end

  def echo(conn, params) do
    response =
      with {:ok, msg} <- Map.fetch(params, :msg) do
        %{
          code: 200,
          message: msg,
          result: "200Ok",
          timestamp: DateTime.utc_now()
        }
      else
        _ ->
          %{
            code: 400,
            message: "Invalid params",
            result: "400BadRequest",
            timestamp: DateTime.utc_now()
          }
      end

    json(conn, response)
  end

  def add_weather(conn, _params) do
    %RainerBlogBackend.Weather{
      city: "New York",
      temp_low: Enum.random(1..20),
      temp_high: Enum.random(21..40),
      prcp: Enum.random(1..10) / 10
    }
    |> RainerBlogBackend.Repo.insert()

    weather =
      RainerBlogBackend.Weather
      |> Ecto.Query.last()
      |> RainerBlogBackend.Repo.one()

    response = %{
      code: 200,
      message: "Weather added",
      result: "200Ok",
      data: %{
        city: weather.city,
        temp_low: weather.temp_low,
        temp_high: weather.temp_high,
        prcp: weather.prcp
      }
    }

    json(conn, response)
  end

  def last_weather(conn, _params) do
    weather = RainerBlogBackend.Weather
    |> Ecto.Query.last()
    |> RainerBlogBackend.Repo.one()

    response = %{
      code: 200,
      message: "Last weather",
      result: "200Ok",
      data: %{
        city: weather.city,
        temp_low: weather.temp_low,
        temp_high: weather.temp_high,
        prcp: weather.prcp
      }
    }
    json(conn, response)
  end
end
