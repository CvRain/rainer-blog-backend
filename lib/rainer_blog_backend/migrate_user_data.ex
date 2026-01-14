defmodule RainerBlogBackend.MigrateUserDataFromCubDB do
  @moduledoc """
  将用户数据从CubDB迁移到PostgreSQL的一次性脚本

  使用方法：
  在iex中运行：
    iex> RainerBlogBackend.MigrateUserDataFromCubDB.migrate()

  或通过mix运行：
    mix run priv/repo/migrate_user_data.exs
  """

  alias RainerBlogBackend.{Repo, User}
  require Logger

  @old_db_path "priv/cubdb/user_config"
  @user_config_key "user_config"

  def migrate do
    Logger.info("开始迁移用户数据从CubDB到PostgreSQL...")

    case CubDB.start_link(@old_db_path, auto_file_sync: false) do
      {:ok, db} ->
        migrate_user_data(db)
        CubDB.stop(db)

      {:error, reason} ->
        Logger.warning("无法打开CubDB数据库: #{inspect(reason)}")
        Logger.info("如果CubDB中没有旧数据，这是正常的")
        {:ok, :no_old_data}
    end
  end

  defp migrate_user_data(db) do
    case CubDB.get(db, @user_config_key) do
      nil ->
        Logger.info("CubDB中没有找到用户配置数据")
        {:ok, :no_data}

      user_config ->
        Logger.info("找到用户配置: #{inspect(Map.drop(user_config, [:user_password]))}")

        # 检查数据库中是否已存在用户
        case User.get_user() do
          nil ->
            # 创建新用户
            attrs = %{
              user_name: user_config.user_name || user_config[:user_name] || "admin",
              user_email: user_config.user_email || user_config[:user_email] || "admin@example.com",
              user_password: user_config.user_password || user_config[:user_password] || "",
              user_signature: user_config.user_signature || user_config[:user_signature] || "",
              user_avatar: user_config.user_avatar || user_config[:user_avatar] || "",
              user_background: user_config.user_background || user_config[:user_background] || ""
            }

            # 注意：密码已经是加密过的，需要直接插入
            case insert_user_with_encrypted_password(attrs) do
              {:ok, user} ->
                Logger.info("成功迁移用户数据到PostgreSQL")
                Logger.info("用户ID: #{user.id}, 用户名: #{user.user_name}")
                {:ok, user}

              {:error, changeset} ->
                Logger.error("迁移用户数据失败: #{inspect(changeset)}")
                {:error, changeset}
            end

          existing_user ->
            Logger.info("数据库中已存在用户: #{existing_user.user_name}")
            Logger.info("跳过迁移（如需更新，请手动操作）")
            {:ok, :already_exists}
        end
    end
  end

  # 直接插入已加密的密码
  defp insert_user_with_encrypted_password(attrs) do
    %User{
      user_name: attrs.user_name,
      user_email: attrs.user_email,
      user_password: attrs.user_password,
      user_signature: attrs.user_signature,
      user_avatar: attrs.user_avatar,
      user_background: attrs.user_background,
      is_active: true
    }
    |> Repo.insert()
  end
end
