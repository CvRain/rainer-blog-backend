# 用户系统迁移指南

## 概述

本次更新将用户信息从 CubDB 迁移到 PostgreSQL 数据库，以获得更好的数据管理能力和扩展性。

## 新增功能

### 新增用户字段

除了原有的基本字段外，新增了以下字段：

- `user_nickname`: 显示昵称（用于前端展示）
- `user_bio`: 个人简介（详细的个人介绍）
- `user_website`: 个人网站链接
- `user_github`: GitHub 用户名
- `user_twitter`: Twitter 用户名
- `user_location`: 所在地
- `is_active`: 账号激活状态

### 字段说明对比

| 字段 | 旧版 (CubDB) | 新版 (PostgreSQL) | 说明 |
|------|-------------|------------------|------|
| user_name | ✓ | ✓ | 用户名（登录用）|
| user_email | ✓ | ✓ | 邮箱 |
| user_password | ✓ | ✓ | 密码（加密存储）|
| user_signature | ✓ | ✓ | 个性签名（简短）|
| user_avatar | ✓ | ✓ | 头像URL |
| user_background | ✓ | ✓ | 背景图URL |
| user_nickname | ✗ | ✓ | 显示昵称 |
| user_bio | ✗ | ✓ | 个人简介 |
| user_website | ✗ | ✓ | 个人网站 |
| user_github | ✗ | ✓ | GitHub |
| user_twitter | ✗ | ✓ | Twitter |
| user_location | ✗ | ✓ | 地理位置 |
| is_active | ✗ | ✓ | 激活状态 |

## 迁移步骤

### 1. 运行数据库迁移

首先创建 users 表：

```bash
mix ecto.migrate
```

### 2. 迁移旧数据（如果有）

如果你之前使用 CubDB 存储了用户数据，运行以下命令将数据迁移到 PostgreSQL：

```bash
mix run priv/repo/migrate_user_data.exs
```

这个脚本会：
- 读取 `priv/cubdb/user_config` 中的旧用户数据
- 将数据迁移到 PostgreSQL 的 users 表
- 保持密码的加密状态
- 如果数据库中已存在用户，则跳过迁移

### 3. 创建默认用户（如果是新安装）

如果是新安装或没有旧数据，可以创建默认用户：

```bash
mix run priv/repo/seeds_user.exs
```

默认用户信息：
- 用户名：`admin`
- 邮箱：`admin@rainerblog.com`
- 密码：`admin123456`

**⚠️ 重要：创建后请立即修改默认密码！**

## API 变更

### 响应格式变化

用户信息 API 响应现在包含更多字段：

```json
{
  "code": 200,
  "message": "获取用户信息成功",
  "data": {
    "id": "uuid",
    "user_name": "admin",
    "user_email": "admin@example.com",
    "user_nickname": "博主",
    "user_signature": "分享技术，记录生活",
    "user_bio": "这是详细的个人简介...",
    "user_avatar": "https://example.com/avatar.jpg",
    "user_background": "https://example.com/bg.jpg",
    "user_website": "https://myblog.com",
    "user_github": "myusername",
    "user_twitter": "myhandle",
    "user_location": "北京",
    "is_active": true,
    "inserted_at": "2026-01-13T00:00:00Z",
    "updated_at": "2026-01-13T00:00:00Z"
  }
}
```

### 更新用户信息 API

现在支持分别更新密码和其他信息：

```bash
# 只更新基本信息（不包含密码）
PATCH /api/user
{
  "user_email": "newemail@example.com",
  "user_nickname": "新昵称",
  "user_bio": "新的个人简介"
}

# 同时更新信息和密码
PATCH /api/user
{
  "user_email": "newemail@example.com",
  "user_password": "newpassword123"
}
```

## 代码变更

### 新增文件

1. `/lib/rainer_blog_backend/user.ex` - User Schema 模块
2. `/priv/repo/migrations/20260113000000_create_users.exs` - 数据库迁移文件
3. `/lib/rainer_blog_backend/migrate_user_data.ex` - 数据迁移模块
4. `/priv/repo/migrate_user_data.exs` - 迁移脚本
5. `/priv/repo/seeds_user.exs` - 用户种子数据

### 修改文件

1. `/lib/rainer_blog_backend/user_config.ex` - 简化为只管理 AWS 配置
2. `/lib/rainer_blog_backend_web/controllers/user_controller.ex` - 使用新的 User 模块

## 数据验证

User 模块包含以下验证规则：

- `user_name`: 必填，2-50字符，唯一
- `user_email`: 必填，邮箱格式，唯一
- `user_password`: 必填，最少6字符（创建/修改密码时）
- `user_nickname`: 最多50字符
- `user_signature`: 最多200字符
- `user_bio`: 最多2000字符
- URL 字段（website, avatar, background）: 必须是有效的 http/https URL

## 兼容性说明

- 旧的 CubDB 数据库路径从 `priv/cubdb/user_config` 更改为 `priv/cubdb/system_config`
- UserConfig 模块仍然保留，但只用于管理 AWS 配置
- 所有用户相关的操作现在通过 User 模块进行
- API 端点保持不变，向后兼容

## 故障排除

### 迁移失败

如果迁移失败，检查：

1. 数据库是否正常运行
2. CubDB 文件路径是否正确
3. 旧数据格式是否完整

### 无法登录

如果迁移后无法登录：

1. 确认用户数据已正确迁移：
   ```elixir
   # 在 iex -S mix 中
   RainerBlogBackend.User.get_user()
   ```

2. 如果用户不存在，重新运行迁移或创建默认用户

### 密码错误

如果提示密码错误：

1. 确认使用的是正确的用户名（不是邮箱）
2. 旧密码应该仍然有效
3. 如果忘记密码，可以通过数据库直接重置

## 后续建议

1. **修改默认密码**：如果使用了默认用户，立即修改密码
2. **配置 JWT 密钥**：将 `user_controller.ex` 中的 `"your-secret-key"` 改为环境变量
3. **完善用户信息**：通过 API 更新个人简介、社交链接等新字段
4. **备份数据**：在清理 CubDB 旧数据前做好备份

## 清理旧数据（可选）

确认迁移成功后，可以删除旧的 CubDB 用户数据：

```bash
# 谨慎操作！确保数据已成功迁移
rm -rf priv/cubdb/user_config
```

注意：`priv/cubdb/system_config` 仍然用于存储 AWS 配置，不要删除！
