# TakeIt iOS

**Paste it. Take it. Save it.**

分享链接媒体提取与下载的 iOS 客户端。粘贴公开分享链接，即可解析、预览并下载原质图片、视频与音频。

本仓库是 [TakeIt](https://github.com/terenzzzz/TakeIt) 的 SwiftUI 客户端，解析能力由 [TakeIt-Backend](https://github.com/terenzzzz/TakeIt-Backend) 提供。

## 功能

- **多平台解析**：MyPPT、LURL、PPT.cc、Twitter / X、抖音、小红书、Instagram
- **粘贴即用**：从剪贴板识别分享链接，也可直接粘贴整段分享文案
- **在线预览**：图片、循环视频、音频预览；部分 CDN 走后端代理以绕过防盗链
- **单文件 / 批量下载**：逐个下载，或一键全部下载，完成后唤起系统分享面板
- **密码短链**：MyPPT / LURL 等受保护链接可弹窗输入密码（常见为上传日期 `MMDD`）
- **最近记录**：本地保存最近 5 条链接，点击输入框可快速回填
- **后端健康检查**：顶部显示在线 / 离线，设置页可修改 API 地址并立即探测
- **深色模式**：跟随系统浅色 / 深色外观
- **URL Scheme**：支持 `takeit://` 从其他 App 唤起并自动解析

## 环境要求

- Mac 与 Xcode（建议与工程部署版本匹配）
- 免费 Apple ID 即可，无需加入付费 Apple Developer Program
- iPhone / iPad，系统不低于 iOS 26.5（与工程 `IPHONEOS_DEPLOYMENT_TARGET` 一致）
- 已部署或本地运行的 [TakeIt-Backend](https://github.com/terenzzzz/TakeIt-Backend)

## 快速开始

### 1. 启动后端

客户端依赖后端 API，请先启动 [TakeIt-Backend](https://github.com/terenzzzz/TakeIt-Backend)：

```bash
cd ../TakeIt-Backend
npm install
cp .env.example .env
npm run dev
```

后端默认运行在 `http://127.0.0.1:3001`。模拟器可直接使用该地址。

### 2. 用 Xcode 打开工程

```bash
open TakeIt.xcodeproj
```

模拟器：顶部设备列表选任意 iPhone 模拟器，按 `⌘R` 运行。

装到自己的手机：按下一节操作。

## 编译并安装到自己的 iPhone

无需上架 App Store。用个人 Apple ID 在 Xcode 里签名，即可把 App 装到自己的设备上。

### 准备手机

1. 用数据线把 iPhone 连到 Mac，解锁手机，点「信任这台电脑」。
2. iOS 16 及以上需打开 **开发者模式**：
   - 设置 → 隐私与安全性 → 开发者模式 → 打开，然后重启
   - 重启后按提示确认开启
3. 确认手机系统 ≥ iOS 26.5。若系统更旧，可在 Xcode 里把 Target `TakeIt` → **General** → **Minimum Deployments** 调低后再编译（更低版本未经验证）。

### 改成你自己的签名

工程里目前的 Team / Bundle ID 是原作者的，你需要换成自己的账号：

1. 左侧选中工程 **TakeIt** → Target **TakeIt** → **Signing & Capabilities**。
2. 勾选 **Automatically manage signing**。
3. **Team** 选 **Add an Account…**，用 Apple ID 登录，再选你的 **Personal Team**。
4. 若 Bundle Identifier `tenenzzzz.TakeIt` 报错（已被占用或无法注册），改成唯一值，例如：

   ```
   com.你的名字.TakeIt
   ```

出现红色签名错误时，先看 Xcode 提示：常见原因是没选 Team、Bundle ID 冲突，或手机未开启开发者模式。

### 编译安装

1. Xcode 顶部设备列表选中你的 **iPhone**（不要选模拟器）。
2. 按 `⌘R`，或菜单 **Product → Run**。
3. 第一次安装后，桌面会出现 TakeIt 图标，但可能还不能打开，需要信任证书：
   - 设置 → 通用 → VPN 与设备管理（或「设备管理」）
   - 点你的 Apple ID 对应的开发者描述文件 → **信任**
4. 再打开 TakeIt。

### 让真机连上后端

真机上的 `127.0.0.1` 指向手机自己，**不能**用来访问电脑上的后端。

**电脑本机跑后端（调试）：**

1. Mac 与 iPhone 连同一 Wi-Fi。
2. 在 Mac 终端查局域网 IP：

   ```bash
   ipconfig getifaddr en0
   ```

3. 打开 TakeIt → 设置，把后端地址改成（端口以你的后端为准）：

   ```
   http://192.168.1.8:3001
   ```

4. 保存后点「立即检查」，顶部应变为「在线」。
5. 若一直离线：检查后端是否在跑、Mac 防火墙是否放行 3001 端口、手机和电脑是否同一网段（部分路由的「AP 隔离」会拦设备互访）。

工程已开启 `NSAllowsLocalNetworking`，因此访问局域网 `http://` 地址是允许的。

**后端已经部署到服务器：**

在设置里填可公网访问的地址，例如 `https://api.example.com`。公网请尽量用 HTTPS；对非本地的明文 `http://`，iOS 可能因 App Transport Security 拦截。

### 免费 Apple ID 的限制

| 项目 | 说明 |
|------|------|
| 证书有效期 | 约 7 天，过期后 App 打不开，用 Xcode 再 `⌘R` 装一次即可 |
| 设备 | 只能装到你自己连接过、并完成信任的设备 |
| App 数量 | 同一 Personal Team 同时安装的 App 数量有限 |

付费开发者账号（每年 $99）签名有效期更长，也不用每周重装。自己用的话，免费账号足够。

### 常见问题

| 现象 | 处理 |
|------|------|
| `Untrusted Developer` / 打不开 | 设置里信任开发者证书 |
| 提示关闭了开发者模式 | 打开开发者模式并重启 |
| Bundle Identifier 无法注册 | 改成独一无二的 ID |
| 顶部一直「离线」 | 真机不要用 `127.0.0.1`，改成电脑局域网 IP 或已部署的后端 |
| 能装上但解析失败 | 先确认 `/health` 通了，再检查后端日志与链接是否受支持 |

## 配置

设置页可修改后端 API 地址，保存在 `UserDefaults`（键名 `takeit.apiBaseURL`）。留空则回退到默认值：

```
http://127.0.0.1:3001
```

客户端会调用：

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/health` | 健康检查（约每 30 秒一次） |
| `POST` | `/api/extract` | 解析分享链接；可选 `password` |
| `GET` | `/api/download` | 代理下载 / 预览媒体 |

接口字段与错误码以 [TakeIt-Backend README](https://github.com/terenzzzz/TakeIt-Backend#api-端点) 为准。

## URL Scheme

Bundle URL Scheme 为 `takeit`，可用于从快捷指令或其他 App 打开并解析：

```
takeit://extract?url=https%3A%2F%2Flurl.cc%2Fabc
takeit://https://x.com/user/status/1
```

传入 `http` / `https` 链接时也会直接填入并提交解析。

## 支持平台

| 平台 | 域名 |
|------|------|
| MyPPT | myppt.cc |
| LURL | lurl.cc |
| PPT.cc | ppt.cc |
| Twitter / X | twitter.com, x.com |
| 抖音 | douyin.com, v.douyin.com, iesdouyin.com |
| 小红书 | xiaohongshu.com, xhslink.com |
| Instagram | instagram.com, instagr.am |

## 项目结构

```
TakeIt/
├── TakeItApp.swift              # App 入口与环境对象
├── ContentView.swift            # 主界面与 URL Scheme 解析
├── Models/                      # 媒体模型、API 错误
├── Services/
│   ├── APIClient.swift          # extract / health / download
│   ├── AppConfig.swift          # 后端地址与超时
│   ├── ExtractorStore.swift     # 解析状态
│   ├── DownloadManager.swift    # 单文件与批量下载
│   ├── MediaSaver.swift         # 缓存写入与格式嗅探
│   ├── HealthMonitor.swift      # 后端健康检查
│   └── RecentURLStore.swift     # 最近链接
├── Views/                       # 输入框、媒体网格、设置、密码弹窗等
└── Theme/                       # 颜色与圆角
TakeItTests/                     # Swift Testing 单元测试
```

## 测试

在 Xcode 中运行 `TakeItTests`，覆盖：

- 平台识别与分享文案提取
- 错误码文案
- 下载 URL 编码
- URL Scheme 解析
- 媒体格式嗅探
- 最近链接去重与上限

## 相关仓库

- [TakeIt](https://github.com/terenzzzz/TakeIt) — Web 前端
- [TakeIt-Backend](https://github.com/terenzzzz/TakeIt-Backend) — 解析与下载 API

## 免责声明

本工具仅用于提取用户有权访问的公开或已获授权媒体资源，请勿用于非法用途。
