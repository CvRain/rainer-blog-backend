# 用户API更新文档 - 改进版

## 🎯 重要更新

### 1. 灵活的链接系统
原有的 `user_website`, `user_github`, `user_twitter` 三个固定字段已被 **`links`** 数组替代。

**优点：**
- ✅ 支持任意数量的链接
- ✅ 支持任意类型的社交媒体
- ✅ 可以添加友情链接
- ✅ 每个链接都有自定义标题

### 2. Base64图片存储
`user_avatar` 和 `user_background` 现在支持 **Base64** 格式，无需上传到S3。

**优点：**
- ✅ 简化架构，不需要额外的对象存储
- ✅ 适合个人博客的单用户场景
- ✅ 支持直接在API中传输图片数据
- ✅ 仍然支持传统的URL格式

---

## 📝 字段说明

### 用户字段列表

| 字段 | 类型 | 说明 | 验证规则 |
|------|------|------|----------|
| `user_name` | string | 用户名（登录用） | 必填，2-50字符，唯一 |
| `user_email` | string | 邮箱 | 必填，邮箱格式，唯一 |
| `user_password` | string | 密码 | 必填，最少6字符（创建/修改时） |
| `user_nickname` | string | 显示昵称 | 最多50字符 |
| `user_signature` | string | 个性签名 | 最多200字符 |
| `user_bio` | text | 详细简介 | 最多2000字符 |
| `user_avatar` | text | 头像 | Base64或URL |
| `user_background` | text | 背景图 | Base64或URL |
| **`links`** | array | **链接列表** | **数组格式，每项含title和url** |
| `user_location` | string | 所在地 | 无限制 |
| `is_active` | boolean | 激活状态 | 默认true |

### Links 字段格式

```json
{
  "links": [
    {
      "title": "GitHub",
      "url": "https://github.com/username"
    },
    {
      "title": "Twitter",
      "url": "https://twitter.com/username"
    },
    {
      "title": "个人博客",
      "url": "https://myblog.com"
    },
    {
      "title": "友链 - 张三的博客",
      "url": "https://zhangsan.blog"
    }
  ]
}
```

**验证规则：**
- 每个链接必须包含 `title` 和 `url` 字段
- `title` 最多50字符
- `url` 必须是有效的 http/https URL

---

## 🚀 API请求示例

### 1. 获取用户信息

```bash
GET /api/user
```

**响应示例：**
```json
{
  "code": 200,
  "message": "获取用户信息成功",
  "data": {
    "id": "38cc0d5d-5014-4391-9e5b-0654797f36ed",
    "user_name": "ClaudeRainer",
    "user_email": "cvraindays@outlook.com",
    "user_nickname": "Rainer",
    "user_signature": "笨拙的探索这个世界",
    "user_bio": "全栈开发者，热爱开源",
    "user_avatar": "data:image/png;base64,iVBORw0KGgoAAAANS...",
    "user_background": "https://example.com/bg.jpg",
    "links": [
      {
        "title": "GitHub",
        "url": "https://github.com/ClaudeRainer"
      },
      {
        "title": "掘金",
        "url": "https://juejin.cn/user/123456"
      },
      {
        "title": "友链 - 李四的博客",
        "url": "https://lisi.dev"
      }
    ],
    "user_location": "北京",
    "is_active": true,
    "inserted_at": "2026-01-13T06:15:39Z",
    "updated_at": "2026-01-16T15:20:00Z"
  }
}
```

---

### 2. 更新链接列表

```javascript
// JavaScript (Axios)
const token = localStorage.getItem('token');

axios.patch('http://localhost:4000/api/user', {
  links: [
    {
      title: 'GitHub',
      url: 'https://github.com/myusername'
    },
    {
      title: 'Twitter',
      url: 'https://twitter.com/myhandle'
    },
    {
      title: 'Bilibili',
      url: 'https://space.bilibili.com/123456'
    },
    {
      title: '个人网站',
      url: 'https://myblog.com'
    },
    {
      title: '友链 - 张三的技术博客',
      url: 'https://zhangsan.tech'
    },
    {
      title: '友链 - 李四的前端笔记',
      url: 'https://lisi.dev'
    }
  ]
}, {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})
  .then(response => console.log(response.data));
```

**cURL示例：**
```bash
curl -X PATCH http://localhost:4000/api/user \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "links": [
      {"title": "GitHub", "url": "https://github.com/username"},
      {"title": "掘金", "url": "https://juejin.cn/user/123456"},
      {"title": "友链 - 小明的博客", "url": "https://xiaoming.blog"}
    ]
  }'
```

---

### 3. 上传Base64头像

```javascript
// 从文件选择器获取图片并转换为Base64
function handleAvatarUpload(event) {
  const file = event.target.files[0];
  const reader = new FileReader();
  
  reader.onload = async (e) => {
    const base64 = e.target.result;  // data:image/png;base64,...
    
    const token = localStorage.getItem('token');
    
    try {
      const response = await axios.patch('http://localhost:4000/api/user', {
        user_avatar: base64
      }, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      console.log('头像更新成功', response.data);
    } catch (error) {
      console.error('上传失败', error);
    }
  };
  
  reader.readAsDataURL(file);
}
```

**HTML示例：**
```html
<input 
  type="file" 
  accept="image/*" 
  onChange="handleAvatarUpload(event)"
/>
```

---

### 4. 完整的用户信息更新示例

```javascript
const token = localStorage.getItem('token');

// 一次性更新多个字段
axios.patch('http://localhost:4000/api/user', {
  user_nickname: '全栈开发者Rainer',
  user_signature: '代码改变世界 🚀',
  user_bio: '我是一名全栈开发者，专注于Web技术栈。喜欢开源，热爱分享。',
  user_location: '北京·海淀',
  user_avatar: 'data:image/jpeg;base64,/9j/4AAQSkZJRg...',  // Base64格式
  user_background: 'data:image/jpeg;base64,/9j/4AAQSkZJRg...',
  links: [
    {
      title: 'GitHub',
      url: 'https://github.com/ClaudeRainer'
    },
    {
      title: 'Twitter',
      url: 'https://twitter.com/ClaudeRainer'
    },
    {
      title: '知乎',
      url: 'https://zhihu.com/people/xxx'
    },
    {
      title: '掘金',
      url: 'https://juejin.cn/user/xxx'
    },
    {
      title: '个人博客',
      url: 'https://clauderainer.com'
    },
    {
      title: '友情链接 - 技术大牛的博客',
      url: 'https://techmaster.blog'
    },
    {
      title: '友情链接 - 前端之路',
      url: 'https://frontend.dev'
    }
  ]
}, {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})
  .then(response => {
    console.log('更新成功', response.data);
  })
  .catch(error => {
    console.error('更新失败', error.response?.data);
  });
```

---

## 🎨 React组件示例

### 链接管理组件

```jsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function LinksManager() {
  const [links, setLinks] = useState([]);
  const [newLink, setNewLink] = useState({ title: '', url: '' });

  // 加载现有链接
  useEffect(() => {
    axios.get('http://localhost:4000/api/user')
      .then(res => {
        if (res.data.code === 200) {
          setLinks(res.data.data.links || []);
        }
      });
  }, []);

  // 添加链接
  const addLink = () => {
    if (newLink.title && newLink.url) {
      setLinks([...links, newLink]);
      setNewLink({ title: '', url: '' });
    }
  };

  // 删除链接
  const removeLink = (index) => {
    setLinks(links.filter((_, i) => i !== index));
  };

  // 保存到服务器
  const saveLinks = async () => {
    const token = localStorage.getItem('token');
    
    try {
      const response = await axios.patch(
        'http://localhost:4000/api/user',
        { links },
        {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        }
      );
      
      if (response.data.code === 200) {
        alert('链接保存成功！');
      }
    } catch (error) {
      alert('保存失败: ' + error.response?.data?.message);
    }
  };

  return (
    <div className="links-manager">
      <h2>链接管理</h2>
      
      {/* 现有链接列表 */}
      <div className="links-list">
        {links.map((link, index) => (
          <div key={index} className="link-item">
            <span className="link-title">{link.title}</span>
            <a href={link.url} target="_blank" rel="noopener noreferrer">
              {link.url}
            </a>
            <button onClick={() => removeLink(index)}>删除</button>
          </div>
        ))}
      </div>

      {/* 添加新链接 */}
      <div className="add-link">
        <h3>添加新链接</h3>
        <input
          type="text"
          placeholder="标题（如：GitHub）"
          value={newLink.title}
          onChange={(e) => setNewLink({ ...newLink, title: e.target.value })}
          maxLength={50}
        />
        <input
          type="url"
          placeholder="URL（如：https://github.com/username）"
          value={newLink.url}
          onChange={(e) => setNewLink({ ...newLink, url: e.target.value })}
        />
        <button onClick={addLink}>添加</button>
      </div>

      <button onClick={saveLinks} className="save-btn">
        保存所有链接
      </button>
    </div>
  );
}

export default LinksManager;
```

### 头像上传组件（Base64）

```jsx
import React, { useState } from 'react';
import axios from 'axios';

function AvatarUpload({ currentAvatar, onSuccess }) {
  const [preview, setPreview] = useState(currentAvatar);
  const [loading, setLoading] = useState(false);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;

    // 检查文件大小（建议不超过2MB）
    if (file.size > 2 * 1024 * 1024) {
      alert('图片大小不能超过2MB');
      return;
    }

    const reader = new FileReader();
    
    reader.onload = async (event) => {
      const base64 = event.target.result;
      setPreview(base64);
      
      // 自动上传
      await uploadAvatar(base64);
    };
    
    reader.readAsDataURL(file);
  };

  const uploadAvatar = async (base64) => {
    setLoading(true);
    const token = localStorage.getItem('token');
    
    try {
      const response = await axios.patch(
        'http://localhost:4000/api/user',
        { user_avatar: base64 },
        {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        }
      );
      
      if (response.data.code === 200) {
        alert('头像更新成功！');
        onSuccess?.(base64);
      }
    } catch (error) {
      alert('上传失败: ' + error.response?.data?.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="avatar-upload">
      <div className="avatar-preview">
        {preview ? (
          <img src={preview} alt="头像预览" />
        ) : (
          <div className="avatar-placeholder">点击上传头像</div>
        )}
      </div>
      
      <input
        type="file"
        accept="image/*"
        onChange={handleFileChange}
        disabled={loading}
      />
      
      {loading && <p>上传中...</p>}
      
      <p className="tip">
        支持 JPG、PNG、GIF 格式，建议大小不超过2MB
      </p>
    </div>
  );
}

export default AvatarUpload;
```

---

## ⚠️ 注意事项

### Base64图片的建议

1. **大小限制**：建议单张图片不超过2MB（Base64后约2.7MB）
2. **压缩处理**：上传前使用前端工具压缩图片
3. **性能考虑**：Base64会增加约33%的数据大小
4. **仍支持URL**：如果有CDN，也可以继续使用URL格式

### Links字段的使用建议

1. **类别分组**：在前端按类型分组显示（社交媒体、友链等）
2. **排序**：数组顺序即显示顺序
3. **图标匹配**：前端可根据title或url匹配相应的图标
4. **验证**：前端应验证URL格式再提交

---

## 🔄 迁移说明

**现有数据自动迁移：**
- ✅ `user_website` → `links[{title: "Website", url: ...}]`
- ✅ `user_github` → `links[{title: "GitHub", url: "https://github.com/..."}]`
- ✅ `user_twitter` → `links[{title: "Twitter", url: "https://twitter.com/..."}]`

你现有的数据已自动转换，无需手动操作！

---

## 📊 错误处理

### Links字段验证错误

```json
{
  "code": 400,
  "message": "更新失败: links: 链接 1 缺少 url 字段",
  "data": null
}
```

### 常见错误：

1. **缺少必填字段**：`"链接 X 缺少 title/url 字段"`
2. **URL格式错误**：`"链接 X 的URL格式不正确"`
3. **标题过长**：`"链接 X 的标题不能超过50个字符"`
4. **类型错误**：`"links 必须是数组格式"`

---

## 💡 实用示例

### 示例1：社交媒体链接

```json
{
  "links": [
    {"title": "GitHub", "url": "https://github.com/username"},
    {"title": "Twitter", "url": "https://twitter.com/username"},
    {"title": "LinkedIn", "url": "https://linkedin.com/in/username"},
    {"title": "掘金", "url": "https://juejin.cn/user/123456"},
    {"title": "知乎", "url": "https://zhihu.com/people/username"},
    {"title": "Bilibili", "url": "https://space.bilibili.com/123456"}
  ]
}
```

### 示例2：友情链接

```json
{
  "links": [
    {"title": "张三的博客", "url": "https://zhangsan.blog"},
    {"title": "李四的技术笔记", "url": "https://lisi.tech"},
    {"title": "王五的前端之路", "url": "https://wangwu.dev"}
  ]
}
```

### 示例3：混合使用

```json
{
  "links": [
    {"title": "📝 个人博客", "url": "https://myblog.com"},
    {"title": "💻 GitHub", "url": "https://github.com/username"},
    {"title": "🐦 Twitter", "url": "https://twitter.com/username"},
    {"title": "🔗 友链-技术大牛", "url": "https://expert.blog"},
    {"title": "🔗 友链-前端菜鸟", "url": "https://newbie.dev"}
  ]
}
```

---

## ✨ 总结

**改进后的优势：**

1. ✅ **更灵活**：不再限制特定的社交媒体平台
2. ✅ **可扩展**：轻松添加新的链接类型
3. ✅ **友链支持**：可以添加任意数量的友情链接
4. ✅ **简化存储**：Base64直接存储图片，无需额外服务
5. ✅ **向后兼容**：旧数据自动迁移

**前端开发建议：**
- 使用图标库（如FontAwesome）根据链接标题显示图标
- 实现拖拽排序功能
- 添加链接预览功能
- 图片上传前进行压缩处理
