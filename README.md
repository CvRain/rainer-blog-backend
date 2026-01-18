# Rainer Blog Backend

个人博客系统的后端API服务，基于 Elixir + Phoenix 构建。

## 技术栈

- **Elixir 1.15+** - 函数式编程语言
- **Phoenix 1.7** - Web框架
- **PostgreSQL** - 主数据库
- **Ecto** - 数据库ORM
- **CubDB** - 轻量级KV存储（用于系统配置）
- **Argon2** - 密码加密
- **Joken** - JWT认证
- **ExAws** - AWS S3对象存储

## 核心功能

### 内容管理
- **主题系统** (Theme) - 顶层内容分类
- **章节管理** (Chapter) - 主题下的章节分组
- **文章管理** (Article) - 支持Markdown，存储在S3
- **收藏集** (Collection) - 资源分组管理
- **资源管理** (Resource) - 文件和媒体资源
- **封面管理** (Cover) - 为内容添加封面图

### 用户系统
- **用户认证** - JWT Token登录验证
- **个人资料** - 昵称、签名、简介、位置等
- **头像/背景图** - 支持Base64或URL存储
- **链接管理** - 灵活的社交媒体和友链系统（JSONB格式）

### 系统功能
- **统计概览** - 文章、主题、收藏集数量统计
- **权限控制** - 公开接口和管理员接口分离
- **CORS支持** - 跨域资源共享
- **S3集成** - 文章内容和资源文件存储

## 快速开始

### 环境要求
- Elixir 1.15+
- PostgreSQL 14+
- Erlang/OTP 25+

### 安装步骤

1. **安装依赖**
   ```bash
   mix deps.get
   ```

2. **配置数据库**
   
   编辑 `config/dev.exs` 设置数据库连接：
   ```elixir
   config :rainer_blog_backend, RainerBlogBackend.Repo,
     username: "postgres",
     password: "postgres",
     hostname: "localhost",
     database: "rainer_blog_backend_dev"
   ```

3. **创建并迁移数据库**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

4. **启动服务器**
   ```bash
   mix phx.server
   ```
   
   或者在IEx中启动：
   ```bash
   iex -S mix phx.server
   ```

5. **访问API**
   
   服务器运行在 `http://localhost:4000`

## API文档

### 用户相关
- `GET /api/user` - 获取用户信息（公开）
- `POST /api/user/login` - 用户登录
- `GET /api/user/verify` - 验证Token
- `PATCH /api/user` - 更新用户信息（需认证）

### 文章相关
- `GET /api/article/public_list` - 获取公开文章列表
- `GET /api/article/one/:id` - 获取文章详情
- `POST /api/article/one` - 创建文章（需认证）
- `PATCH /api/article/one` - 更新文章（需认证）
- `DELETE /api/article/one/:id` - 删除文章（需认证）

### 主题相关
- `GET /api/theme/active` - 获取激活主题列表
- `GET /api/theme/one/:id` - 获取主题详情
- `POST /api/theme/one` - 创建主题（需认证）

详细API文档请参考：[USER_API_UPDATED.md](USER_API_UPDATED.md)

## 数据模型

```
Theme (主题)
  └── Chapter (章节)
      └── Article (文章)

Collection (收藏集)
  └── Resource (资源)

User (用户)
  ├── Links (社交链接列表)
  ├── Avatar (头像 - Base64/URL)
  └── Background (背景图 - Base64/URL)
```

## 配置说明

### JWT密钥配置
建议将JWT密钥移至环境变量：
```bash
export JWT_SECRET="your-secret-key-here"
```

### S3配置
通过API设置S3配置（存储在CubDB）：
```bash
POST /api/s3/config
Authorization: Bearer <token>

{
  "access_key_id": "your-key",
  "secret_access_key": "your-secret",
  "region": "us-east-1",
  "bucket": "your-bucket",
  "endpoint": "s3.amazonaws.com"
}
```

## 开发指南

### 运行测试
```bash
mix test
```

### 代码格式化
```bash
mix format
```

### 数据库操作
```bash
# 创建数据库
mix ecto.create

# 运行迁移
mix ecto.migrate

# 回滚迁移
mix ecto.rollback

# 重置数据库
mix ecto.reset
```

## 生产部署

1. **设置环境变量**
   ```bash
   export SECRET_KEY_BASE="..."
   export DATABASE_URL="..."
   export JWT_SECRET="..."
   ```

2. **编译生产版本**
   ```bash
   MIX_ENV=prod mix compile
   ```

3. **运行迁移**
   ```bash
   MIX_ENV=prod mix ecto.migrate
   ```

4. **启动服务**
   ```bash
   MIX_ENV=prod mix phx.server
   ```

详细部署指南请参考：[Phoenix部署文档](https://hexdocs.pm/phoenix/deployment.html)

## 项目结构

```
lib/
├── rainer_blog_backend/          # 业务逻辑层
│   ├── article.ex                # 文章模型
│   ├── chapter.ex                # 章节模型
│   ├── collection.ex             # 收藏集模型
│   ├── theme.ex                  # 主题模型
│   ├── resource.ex               # 资源模型
│   ├── user.ex                   # 用户模型
│   ├── cover.ex                  # 封面模型
│   ├── user_config.ex            # 系统配置（CubDB）
│   ├── aws_service.ex            # S3服务
│   └── repo.ex                   # 数据库仓库
│
└── rainer_blog_backend_web/      # Web层
    ├── controllers/              # 控制器
    ├── plugs/                    # 中间件
    │   └── auth_plug.ex          # JWT认证
    ├── types/                    # 类型定义
    ├── endpoint.ex               # 端点配置
    └── router.ex                 # 路由配置
```

## 常见问题

### Q: 如何初始化用户？
A: 首次启动时，使用以下curl创建用户（通过直接调用Ecto）：
```elixir
iex> RainerBlogBackend.User.create_user(%{
  user_name: "admin",
  user_email: "admin@example.com",
  user_password: "your_password"
})
```

### Q: 图片应该用Base64还是S3？
A: 
- **用户头像/背景图**：推荐Base64（简单，适合单用户）
- **文章内容图片**：推荐S3（节省数据库空间）
- **资源文件**：使用S3

### Q: 如何配置CORS？
A: 在 `config/config.exs` 中配置允许的源：
```elixir
config :cors_plug,
  origin: ["http://localhost:3000", "https://yourdomain.com"]
```

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 相关链接

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir官网](https://elixir-lang.org/)
- [Ecto文档](https://hexdocs.pm/ecto/)
- [ExAws文档](https://hexdocs.pm/ex_aws/)
