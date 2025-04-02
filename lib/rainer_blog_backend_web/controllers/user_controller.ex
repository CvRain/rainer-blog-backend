defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller
  alias RainerBlogBackendWeb.RequestSchema.RegisterRequest
  alias RainerBlogBackend.User
  alias RainerBlogBackendWeb.Response

  def show(conn, params) do
  end

  def update(conn, params) do
  end

  def login(conn, params) do
  end

  def register(conn, params) do
    case RegisterRequest.changeset(params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        user_params = Ecto.Changeset.apply_changes(changeset)

        user_attrs =
          %{
            name: user_params.name,
            email: user_params.email,
            password: user_params.password
          }

        with false <- User.exist_by_email(user_params.email),
             false <- User.exist_by_name(user_params.name),
             {:ok, user} <- User.add_user(user_attrs) do
          json(
            conn,
            Response.base_response(201, "201Created", "User created successfully", %{id: user.id})
          )
        else
          true ->
            json(
              conn,
              Response.base_response(409, "409Conflict", "Email or username already exists", %{})
            )

          {:error, changeset} ->
            json(
              conn,
              Response.base_response(400, "400BadRequest", "Validation failed", %{
                errors: transform_errors(changeset)
              })
            )
        end

      %Ecto.Changeset{valid?: false} = changeset ->
        json(
          conn,
          Response.base_response(400, "400BadRequest", "Invalid request parameters", %{
            errors: transform_errors(changeset)
          })
        )
    end
  end

  defp transform_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
