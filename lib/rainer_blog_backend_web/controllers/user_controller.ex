defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackend.User
  alias RainerBlogBackend.Repo
  alias RainerBlogBackendWeb.Types.BaseResponse

  def check_user(conn, _params) do
    exists = User.user_exists?()
    response = BaseResponse.generate(200, "success", %{exists: exists})

    conn
    |> put_status(response.code)
    |> json(response)
  end

  def create(conn, params) do
    response =
      with {:ok, name} <- validate_param_present(params["name"], "name is required"),
           {:ok, password} <- validate_param_present(params["password"], "password is required"),
           {:ok, _} <- validate_user_not_exists() do
        user = User.create_user(name, password)
        BaseResponse.generate(201, "success", %{
          name: user.name,
          signature: user.signature,
          avatar: user.avatar,
          background: user.background
        })
      else
        {:error, message} when is_binary(message) ->
          BaseResponse.generate(400, message, nil)
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

  def show(conn, _params) do
    user = User.get_user()

    response = BaseResponse.generate(200, "success", %{
      name: user.name,
      signature: user.signature,
      avatar: user.avatar,
      background: user.background
    })

    conn
    |> put_status(response.code)
    |> json(response)
  end

  def update(conn, params) do
    response =
      with {:ok, attrs} <- validate_update_params(params),
           user <- User.update_user(attrs) do
        BaseResponse.generate(200, "success", %{
          name: user.name,
          signature: user.signature,
          avatar: user.avatar,
          background: user.background
        })
      else
        {:error, message} ->
          BaseResponse.generate(400, message, nil)
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

  defp validate_user_not_exists do
    if User.user_exists?() do
      {:error, "User already exists"}
    else
      {:ok, nil}
    end
  end

  defp validate_update_params(params) do
    allowed_fields = ["name", "signature", "avatar", "background"]
    attrs = Map.take(params, allowed_fields)

    if map_size(attrs) == 0 do
      {:error, "No valid fields to update"}
    else
      {:ok, attrs}
    end
  end
end
