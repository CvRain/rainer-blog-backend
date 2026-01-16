alias RainerBlogBackend.User

# 测试更新links
user = User.get_user()

test_links = [
  %{"title" => "GitHub", "url" => "https://github.com/ClaudeRainer"},
  %{"title" => "掘金", "url" => "https://juejin.cn/user/123456"},
  %{"title" => "友链 - 张三的博客", "url" => "https://zhangsan.blog"}
]

IO.puts("\n测试新的Links功能...")
IO.puts(String.duplicate("=", 60))

case User.update_user(user, %{links: test_links}) do
  {:ok, updated_user} ->
    IO.puts("✓ Links 更新成功！")
    IO.puts("\n当前用户信息:")
    IO.puts("  用户名: #{updated_user.user_name}")
    IO.puts("  邮箱: #{updated_user.user_email}")
    IO.puts("\n  Links列表:")
    Enum.each(updated_user.links, fn link ->
      IO.puts("    - #{link["title"]}: #{link["url"]}")
    end)

  {:error, changeset} ->
    IO.puts("✗ 更新失败:")
    IO.inspect(changeset.errors)
end

IO.puts(String.duplicate("=", 60))
