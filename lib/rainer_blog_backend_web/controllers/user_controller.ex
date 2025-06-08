defmodule RainerBlogBackendWeb.UserController do
  use RainerBlogBackendWeb, :controller

  alias RainerBlogBackendWeb.Types.BaseResponse
  alias RainerBlogBackend.UserConfig

  def show(conn, _params) do
    user_config = UserConfig.get_user_config()
    # 在返回时移除密码字段
    safe_config = Map.drop(user_config, [:user_password])
    json(conn, BaseResponse.generate(200, "获取用户配置成功", safe_config))
  end

  def update(conn, _params) do
    try do
      case validate_user_config(conn.body_params) do
        {:ok, valid_config} ->
          # 对密码进行加密
          encrypted_config = encrypt_password(valid_config)
          UserConfig.update_user_config(encrypted_config)
          # 返回时移除密码字段
          safe_config = Map.drop(encrypted_config, [:user_password])
          json(conn, BaseResponse.generate(200, "更新用户配置成功", safe_config))

        {:error, reason} ->
          json(conn, BaseResponse.generate(400, "更新用户配置失败: #{reason}", nil))
      end
    rescue
      e in MatchError ->
        json(conn, BaseResponse.generate(500, "服务器内部错误: #{inspect(e)}", nil))
      e ->
        json(conn, BaseResponse.generate(500, "服务器内部错误: #{inspect(e)}", nil))
    end
  end

  defp validate_user_config(params) do
    required_fields = ["user_name", "user_email", "user_password"]
    optional_fields = ["user_signature", "user_avatar", "user_background"]

    # 检查必填字段
    missing_fields = Enum.filter(required_fields, &(is_nil(params[&1]) or params[&1] == ""))

    if Enum.empty?(missing_fields) do
      # 构建配置映射
      config = Map.new(required_fields ++ optional_fields, fn field ->
        {String.to_atom(field), params[field] || ""}
      end)

      {:ok, config}
    else
      {:error, "缺少必填字段: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  defp encrypt_password(config) do
    case config.user_password do
      "" -> config
      password ->
        hashed_password = Argon2.hash_pwd_salt(password)
        Map.put(config, :user_password, hashed_password)
    end
  end
end
