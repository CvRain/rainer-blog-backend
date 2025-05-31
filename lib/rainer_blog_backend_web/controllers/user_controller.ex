defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.User
  alias RainerBlogBackend.Repo

  def create(conn, _params) do
    request_body = conn.body_params

    case {request_body["name"], request_body["password"]} do
      {nil, _} ->
        conn
        |> put_status(400)
        |> json(%{error: "user name is required"})

      {_, nil} ->
        conn
        |> put_status(400)
        |> json(%{error: "password is required"})

      {name, password} ->
        changeset = User.changeset(%User{}, %{name: name, password: password})

        case Repo.insert(changeset) do
          {:ok, user} ->
            conn
            |> put_status(201)
            |> json(%{data: "create user success", user: user})

          {:error, changeset} ->
            conn
            |> put_status(422)
            |> json(%{error: changeset_errors(changeset)})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      user ->
        Repo.delete(user)
        conn
        |> put_status(:no_content)
        |> json(%{})
    end
  end

  def show(conn, %{"user_id" => user_id}) do
    case Repo.get(User, user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      user ->
        conn
        |> put_status(:ok)
        |> json(%{data: user})
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
