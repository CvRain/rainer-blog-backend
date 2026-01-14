#!/usr/bin/env elixir

# 测试用户系统迁移后的功能
# 运行方式: mix run test_user_migration.exs

alias RainerBlogBackend.{User, Repo}

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("用户系统迁移测试")
IO.puts(String.duplicate("=", 70))

# 1. 测试获取用户
IO.puts("\n1. 测试获取用户...")
case User.get_user() do
  nil ->
    IO.puts("  ✗ 未找到用户")
  user ->
    IO.puts("  ✓ 成功获取用户: #{user.user_name}")
    IO.puts("    邮箱: #{user.user_email}")
end

# 2. 测试更新用户信息
IO.puts("\n2. 测试更新用户信息...")
user = User.get_user()
if user do
  case User.update_user(user, %{
    user_nickname: "Rainer",
    user_bio: "这是一个测试简介",
    user_location: "北京"
  }) do
    {:ok, updated_user} ->
      IO.puts("  ✓ 成功更新用户信息")
      IO.puts("    昵称: #{updated_user.user_nickname}")
      IO.puts("    简介: #{updated_user.user_bio}")
      IO.puts("    位置: #{updated_user.user_location}")
    {:error, changeset} ->
      IO.puts("  ✗ 更新失败: #{inspect(changeset.errors)}")
  end
end

# 3. 测试安全信息获取（不包含密码）
IO.puts("\n3. 测试安全信息获取...")
user = User.get_user()
if user do
  safe_user = User.safe_user(user)
  IO.puts("  ✓ 安全用户信息（无密码）:")
  IO.puts("    用户名: #{safe_user["user_name"]}")
  IO.puts("    包含密码字段: #{Map.has_key?(safe_user, "user_password") || Map.has_key?(safe_user, :user_password)}")
end

# 4. 测试用户名查询
IO.puts("\n4. 测试用户名查询...")
user = User.get_user()
if user do
  found_user = User.get_user_by_username(user.user_name)
  if found_user do
    IO.puts("  ✓ 成功通过用户名查找用户: #{found_user.user_name}")
  else
    IO.puts("  ✗ 未找到用户")
  end
end

# 5. 测试密码验证
IO.puts("\n5. 测试密码验证...")
user = User.get_user()
if user do
  # 注意：这里无法测试原始密码，因为我们不知道原始密码
  IO.puts("  ℹ 密码已加密存储，可以通过登录API测试")
  IO.puts("    密码哈希: #{String.slice(user.user_password, 0..20)}...")
end

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("测试完成！")
IO.puts(String.duplicate("=", 70) <> "\n")
