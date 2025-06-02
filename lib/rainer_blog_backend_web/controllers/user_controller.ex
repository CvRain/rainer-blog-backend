defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.User
  alias RainerBlogBackend.Repo
  alias RainerBlogBackendWeb.Types.BaseResponse

  def create(conn, _params) do
    request_body = conn.body_params

    response =
      with {:ok, name} <- validate_param_present(request_body["name"], "name is required"),
           {:ok, password} <-
             validate_param_present(request_body["password"], "password is required"),
           {:ok, user} <- User.create_user(name, password) do
        BaseResponse.generate(201, "success", %{
          id: user.id,
          name: user.name,
          inserted_at: user.inserted_at
        })
      else
        {:error, message} when is_binary(message) ->
          BaseResponse.generate(400, message, nil)

        {:error, changeset} ->
          BaseResponse.generate(422, "validation error", changeset_errors(changeset))

        _ ->
          BaseResponse.generate(500, "An unexpected server error occurred.", nil)
      end

    conn
    |> put_status(response.code)
    |> json(response)
  end

  def delete(conn, %{"id" => id}) do
    response =
      case Repo.get(User, id) do
        nil ->
          BaseResponse.generate(404, "User not found", nil)

        user ->
          case Repo.delete(user) do
            {:ok, _} -> BaseResponse.generate(204, "success", nil)
            {:error, _} -> BaseResponse.generate(500, "failed to delete user", nil)
          end
      end

    conn
    |> put_status(response.code)
    |> json(response)
  end

  def show(conn, %{"user_id" => user_id}) do
    response =
      case user_id do
        nil ->
          BaseResponse.generate(400, "user_id is required", nil)

        user_id ->
          try do
            case Repo.get(User, user_id) do
              nil ->
                BaseResponse.generate(404, "User not found", nil)

              user ->
                BaseResponse.generate(200, "success", %{
                  id: user.id,
                  name: user.name,
                  inserted_at: user.inserted_at
                })
            end
          rescue
            Ecto.Query.CastError ->
              BaseResponse.generate(400, "Invalid user_id format", nil)

            e in Ecto.Query.CastError ->
              BaseResponse.generate(400, "Invalid user_id format", e)

            _ ->
              BaseResponse.generate(500, "Internal server error", nil)
          end
      end

    conn
    |> put_status(response.code)
    |> json(response)
  end

  def hello(conn, _params) do
    response = BaseResponse.generate(200, "success", "hello")

    conn
    |> put_status(response.code)
    |> json(response)
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp validate_param_present(value, error_message) when is_nil(value) or value == "",
    do: {:error, error_message}

  defp validate_param_present(value, _error_message), do: {:ok, value}
end
