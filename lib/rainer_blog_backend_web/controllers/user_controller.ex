defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller
  alias RainerBlogBackend.User
  alias RainerBlogBackend.Repo
  import Comeonin.Bcrypt, only: [checkpw: 2, hashpwsalt: 1]
  import RainerBlogBackend.Guardian, only: [encode_and_sign: 1] # 假设使用Guardian库生成JWT

  def show(conn, params) do
  end

  def update(conn, params) do
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Repo.get_by(User, email: email) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{result: "error", message: "用户不存在", code: 401, data: nil})

      user ->
        if checkpw(password, user.password) do
          {:ok, token, _claims} = encode_and_sign(user)
          conn
          |> put_status(:ok)
          |> json(%{result: "success", message: "登录成功", code: 200, data: %{token: token, user: user}})
        else
          conn
          |> put_status(:unauthorized)
          |> json(%{result: "error", message: "密码错误", code: 401, data: nil})
        end
    end
  end

  def register(conn, %{"name" => name, "email" => email, "password" => password}) do
    hashed_password = hashpwsalt(password)
    case User.add_user(name, email, hashed_password) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{result: "success", message: "注册成功", code: 201, data: user})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{result: "error", message: "注册失败", code: 422, data: changeset.errors})
    end
  end
end
