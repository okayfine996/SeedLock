# Seedlock Support Website

这是为 App Store 上架准备的技术支持网站文件。

## 📁 文件说明

- `index.html` - 主支持页面（包含 FAQ、联系方式等）
- `privacy.html` - 隐私政策页面
- `terms.html` - 服务条款页面

## 🚀 免费部署方案

### 方案 1: Netlify（推荐，最简单）⭐

**优点：** 免费、简单、支持自定义域名、自动 HTTPS

**步骤：**

1. 访问 [Netlify](https://www.netlify.com)
2. 使用 GitHub 账号登录
3. 点击 "Add new site" → "Import an existing project"
4. 选择 "Deploy manually"
5. 将 `support-website` 文件夹中的所有文件拖拽到上传区域
6. 等待部署完成（约 30 秒）
7. 你会得到一个免费域名：`https://[随机名称].netlify.app`
8. 可以在 Site settings → Change site name 中修改名称

**你的网站地址：**
```
https://[你的网站名].netlify.app
```

---

### 方案 2: Vercel（推荐，快速）

**优点：** 免费、极速部署、支持自定义域名

**步骤：**

1. 访问 [Vercel](https://vercel.com)
2. 使用 GitHub 账号登录
3. 点击 "Add New Project"
4. 选择 "Import Git Repository" 或 "Deploy" → "Browse"
5. 如果选择 Deploy，直接上传 `support-website` 文件夹
6. 等待部署完成
7. 你会得到一个免费域名：`https://[项目名].vercel.app`

**你的网站地址：**
```
https://[你的项目名].vercel.app
```

---

### 方案 3: Cloudflare Pages（免费，CDN 加速）

**优点：** 免费、全球 CDN、速度快

**步骤：**

1. 访问 [Cloudflare Pages](https://pages.cloudflare.com)
2. 使用 Cloudflare 账号登录（免费注册）
3. 点击 "Create a project"
4. 选择 "Upload assets"
5. 上传 `support-website` 文件夹中的所有文件
6. 等待部署完成
7. 你会得到一个免费域名：`https://[项目名].pages.dev`

**你的网站地址：**
```
https://[你的项目名].pages.dev
```

---

### 方案 4: GitHub Pages（如果可用）

**注意：** GitHub Pages 对个人用户也是免费的，但如果你遇到限制，可以使用上面的方案。

**步骤：**

1. 在 GitHub 创建新仓库（Public）
2. 上传所有 HTML 文件
3. Settings → Pages → Source: Deploy from a branch → main → / (root)
4. 网站地址：`https://[用户名].github.io/[仓库名]/`

---

### 方案 5: 使用现有网站的子目录

如果你已经有网站，可以将这些 HTML 文件上传到你的网站服务器。

---

## ✏️ 在 App Store Connect 中使用

部署完成后，在 App Store Connect 中填写：

1. **Support URL**: `https://[你的网站地址]/`
2. **Privacy Policy URL**: `https://[你的网站地址]/privacy.html`

例如（使用 Netlify）：
- Support URL: `https://seedlock-support.netlify.app/`
- Privacy Policy URL: `https://seedlock-support.netlify.app/privacy.html`

---

## 🎨 自定义

### 修改邮箱地址

在所有 HTML 文件中搜索 `litesky@foxmail.com` 并替换为你的实际邮箱。

### 修改 App Store 链接

在 `index.html` 中搜索 `https://apps.apple.com/app/seedlock` 并替换为你的实际 App Store 链接。

### 修改颜色主题

在 HTML 文件的 `<style>` 部分，你可以修改：
- `#667eea` - 主色调（紫色）
- `#764ba2` - 渐变色（深紫色）

---

## ✅ 推荐方案对比

| 方案 | 难度 | 速度 | 自定义域名 | 推荐度 |
|------|------|------|-----------|--------|
| Netlify | ⭐ 简单 | 快 | ✅ 支持 | ⭐⭐⭐⭐⭐ |
| Vercel | ⭐ 简单 | 很快 | ✅ 支持 | ⭐⭐⭐⭐⭐ |
| Cloudflare Pages | ⭐⭐ 中等 | 很快 | ✅ 支持 | ⭐⭐⭐⭐ |
| GitHub Pages | ⭐⭐ 中等 | 中等 | ✅ 支持 | ⭐⭐⭐ |

**推荐使用 Netlify 或 Vercel**，它们最简单且完全免费。

---

## 📱 测试清单

部署后，请务必：
- [ ] 在电脑浏览器中打开网站检查
- [ ] 在 iPhone 上打开网站检查移动端显示
- [ ] 测试所有链接（Privacy Policy、Terms of Service）
- [ ] 确认邮箱链接可以正常打开邮件客户端
- [ ] 在 App Store Connect 中填写 URL

---

## 🎉 完成！

你的技术支持网站现在已经准备好了！可以用于 App Store 上架。

