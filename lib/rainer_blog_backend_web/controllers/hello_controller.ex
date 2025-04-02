defmodule RainerBlogBackendWeb.HelloController do
  use RainerBlogBackendWeb, :controller

  import Ecto.Query

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
    msg = Map.get(params, "msg") || Map.get(params, :msg)

    response =
      if msg do
        %{
          code: 200,
          message: msg,
          result: "200Ok",
          timestamp: DateTime.utc_now()
        }
      else
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
    body_request = conn.body_params

    case RainerBlogBackend.Repo.insert(%RainerBlogBackend.Weather{
           city: body_request["city"],
           temp_low: body_request["temp_low"],
           temp_high: body_request["temp_high"],
           prcp: body_request["prcp"]
         }) do
      {:ok, weather} ->
        json(
          conn,
          %{
            code: 201,
            message: "Weather added",
            result: "201Created",
            data: weather
          }
        )

      {:error, changeset} ->
        json(conn, %{
          code: 400,
          message: "Invalid data: #{inspect(changeset.errors)}",
          result: "400BadRequest"
        })
    end
  end

  def last_weather(conn, _params) do
    weather =
      RainerBlogBackend.Weather
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
