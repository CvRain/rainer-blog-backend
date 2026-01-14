defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackend.User

  def show(conn, _params) do
    case User.get_user() do
      nil ->
        json(conn, BaseResponse.generate(404, "用户不存在", nil))

      user ->
        safe_user = User.safe_user(user)
        json(conn, BaseResponse.generate(200, "获取用户信息成功", safe_user))
    end
  end

  def update(conn, _params) do
    try do
      user = User.get_user()

      if is_nil(user) do
        json(conn, BaseResponse.generate(404, "用户不存在", nil))
      else
        # 如果包含密码字段，单独处理
        {password, attrs} = Map.pop(conn.body_params, "user_password")

        result =
          if password && password != "" do
            # 先更新其他字段，再更新密码
            with {:ok, updated_user} <- User.update_user(user, attrs),
                 {:ok, final_user} <- User.update_password(updated_user, password) do
              {:ok, final_user}
            end
          else
            User.update_user(user, attrs)
          end

        case result do
          {:ok, updated_user} ->
            safe_user = User.safe_user(updated_user)
            json(conn, BaseResponse.generate(200, "更新用户信息成功", safe_user))

          {:error, %Ecto.Changeset{} = changeset} ->
            errors = format_changeset_errors(changeset)
            json(conn, BaseResponse.generate(400, "更新失败: #{errors}", nil))

          {:error, reason} ->
            json(conn, BaseResponse.generate(400, "更新失败: #{inspect(reason)}", nil))
        end
      end
    rescue
      e ->
        json(conn, BaseResponse.generate(500, "服务器内部错误: #{inspect(e)}", nil))
    end
  end

  def login(conn, _params) do
    try do
      user_name = conn.body_params["user_name"]
      user_password = conn.body_params["user_password"]

      if is_nil(user_name) or is_nil(user_password) do
        json(conn, BaseResponse.generate(400, "用户名和密码不能为空", nil))
      else
        case User.get_user_by_username(user_name) do
          nil ->
            json(conn, BaseResponse.generate(401, "用户名或密码错误", nil))

          user ->
            if User.verify_password(user, user_password) do
              # 生成 JWT token
              token = generate_token(user)
              # 返回用户信息和token
              safe_user = User.safe_user(user)

              json(
                conn,
                BaseResponse.generate(200, "登录成功", %{
                  user: safe_user,
                  token: token
                })
              )
            else
              json(conn, BaseResponse.generate(401, "用户名或密码错误", nil))
            end
        end
      end
    rescue
      e ->
        json(conn, BaseResponse.generate(500, "服务器内部错误: #{inspect(e)}", nil))
    end
  end

  def verify_token(conn, _params) do
    try do
      token =
        get_req_header(conn, "authorization")
        |> List.first()
        |> String.replace("Bearer ", "")

      case verify_token(token) do
        {:ok, claims} ->
          json(conn, BaseResponse.generate(200, "Token 有效", claims))

        {:error, reason} ->
          json(conn, BaseResponse.generate(401, "Token 无效: #{reason}", nil))
      end
    rescue
      e ->
        json(conn, BaseResponse.generate(500, "服务器内部错误: #{inspect(e)}", nil))
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      "#{field}: #{Enum.join(errors, ", ")}"
    end)
    |> Enum.join("; ")
  end

  defp generate_token(user) do
    signer = Joken.Signer.create("HS256", "your-secret-key")

    {:ok, token, _claims} =
      Joken.encode_and_sign(
        %{
          "user_id" => user.id,
          "user_name" => user.user_name,
          "user_email" => user.user_email
        },
        signer
      )

    token
  end

  defp verify_token(token) do
    signer = Joken.Signer.create("HS256", "your-secret-key")

    case Joken.verify(token, signer) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end
end
