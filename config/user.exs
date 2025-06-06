import Config

config :rainer_blog_backend, :user,
  name: "Rainer",
  password: Bcrypt.hash_pwd_salt("your_password"), # 请在生产环境中修改此密码
  signature: "个人博客",
  avatar: "/images/default-avatar.png",
  background: "/images/default-background.jpg"
