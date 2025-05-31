defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.User
  alias RainerBlogBackend.Repo

  def create(conn, _params) do
    request_body = conn.body_params

    response = case {request_body["name"], request_body["password"]} do
      {nil, _} -> %{
        code: 400,
        message: "name is required",
        data: nil
      }
      {_, nil} -> %{
        code: 400,
        message: "password is required",
        data: nil
      }
      {name, password} ->
        changeset = User.changeset(%User{}, %{name: name, password: password})

        case Repo.insert(changeset) do
          {:ok, user} -> %{
            code: 201,
            message: "success",
            data: %{
              id: user.id,
              name: user.name,
              inserted_at: user.inserted_at
            }
          }
          {:error, changeset} -> %{
            code: 422,
            message: "validation error",
            data: changeset_errors(changeset)
          }
        end
    end

    conn
    |> put_status(response.code)
    |> json(response)
  end

  def delete(conn, %{"id" => id}) do
    response = case Repo.get(User, id) do
      nil -> %{
        code: 404,
        message: "User not found",
        data: nil
      }
      user ->
        Repo.delete(user)
        %{
          code: 204,
          message: "success",
          data: nil
        }
    end

    conn
    |> put_status(response.code)
    |> json(response)
  end

  def show(conn, %{"user_id" => user_id}) do
    response = case Repo.get(User, user_id) do
      nil -> %{
        code: 404,
        message: "User not found",
        data: nil
      }
      user -> %{
        code: 200,
        message: "success",
        data: %{
          id: user.id,
          name: user.name,
          inserted_at: user.inserted_at
        }
      }
    end

    conn
    |> put_status(response.code)
    |> json(response)
  end

  def hello(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
      code: 200,
      message: "success",
      data: "hello"
    })
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
