# 初始化用户数据的种子脚本
#
# 使用方法:
# 1. 如果有旧的CubDB数据，先运行: mix run priv/repo/migrate_user_data.exs
# 2. 如果没有旧数据，运行此脚本创建默认用户: mix run priv/repo/seeds_user.exs

alias RainerBlogBackend.{Repo, User}

# 检查是否已存在用户
case User.get_user() do
  nil ->
    # 创建默认用户
    IO.puts("创建默认用户...")

    case User.create_user(%{
           user_name: "admin",
           user_email: "admin@rainerblog.com",
           user_password: "admin123456",
           user_nickname: "博主",
           user_signature: "分享技术，记录生活",
           user_bio: "欢迎来到我的博客",
           is_active: true
         }) do
      {:ok, user} ->
        IO.puts("✓ 成功创建默认用户")
        IO.puts("  用户名: #{user.user_name}")
        IO.puts("  邮箱: #{user.user_email}")
        IO.puts("  默认密码: admin123456")
        IO.puts("  请尽快修改默认密码！")

      {:error, changeset} ->
        IO.puts("✗ 创建用户失败:")
        IO.inspect(changeset.errors)
    end

  user ->
    IO.puts("用户已存在: #{user.user_name}")
    IO.puts("跳过用户创建")
end
