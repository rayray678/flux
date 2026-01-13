[English](README_EN.md) | 简体中文 | [繁體中文](docs/README_TW.md) | [日本語](docs/README_JA.md) | [한국어](docs/README_KO.md) | [Русский](docs/README_RU.md) | [हिन्दी](docs/README_HI.md) | [Español](docs/README_ES.md) | [Português](docs/README_PT.md) | [Français](docs/README_FR.md) | [Deutsch](docs/README_DE.md) | [العربية](docs/README_AR.md) | [Türkçe](docs/README_TR.md) | [Tiếng Việt](docs/README_VI.md) | [ไทย](docs/README_TH.md) | [Indonesia](docs/README_ID.md)

# Flux - Open Source V2Board Client

**Flux** 是一个完美适配 [V2Board](https://github.com/wyx2685/v2board) 的跨平台客户端。

我们致力于提供最简单、最流畅的对接体验。如果您正在运营 V2Board 面板，Flux 是您客户端的最佳选择。

---

## 📞 定制与商业支持

如果您需要：
-   🔥 **修改 App 名称和 Logo**
-   🎨 **定制专属 UI 主题**
-   🚀 **增加高级功能**


请通过 Telegram 联系我：👉 **[@xiaoxiaonihaoya](https://t.me/xiaoxiaonihaoya)**

---

## 📱 界面预览

### 📱 App 版本

| | | |
| :---: | :---: | :---: |
| <img src="assets/images/screenshots/1.png" width="200"> | <img src="assets/images/screenshots/2.png" width="200"> | <img src="assets/images/screenshots/3.png" width="200"> |
| <img src="assets/images/screenshots/4.png" width="200"> | <img src="assets/images/screenshots/5.png" width="200"> | |

### 💻 桌面版本

| | |
| :---: | :---: |
| <img src="assets/images/screenshots/6.png" width="200"> | <img src="assets/images/screenshots/7.png" width="200"> |
| <img src="assets/images/screenshots/8.png" width="200"> | <img src="assets/images/screenshots/9.png" width="200"> |

---

## 🎉 核心优势

-   **极简对接**: 真的只需要**一步**！修改 API 地址即可直接使用，告别繁琐配置。
-   **多种协议**: 支持 VLESS, VMess, Trojan, Shadowsocks。
-   **全平台支持**: Android, iOS, Windows, macOS, Linux 全覆盖。
-   **开源透明**: 代码完全开源，安全可控，随时定制。
-   **多语言支持**: 支持英语、简体中文、繁体中文、日语、韩语、俄语、西班牙语等多种语言。

---

## 🔧 技术原理 & 内核揭秘

Flux 不仅仅是一个简单的 UI 壳，它底层集成了强大的路由核心，确保了跨平台的稳定连接。

### 1. 核心架构 (Core Architecture)

*   **UI 层**: 基于 **Flutter** 构建，一套代码适配 5 端，保证了视觉和交互的高度统一。
*   **逻辑层**: 通过 `UnifiedVpnService` 统一调度，根据当前运行平台自动选择最佳的流量接管方式。
*   **内核层**: 内置 **V2Ray / Xray Core**，它是流量处理的心脏，负责协议封装、加密和路由分流。

### 2. 流量转发原理 (Traffic Forwarding)

Flux 在不同平台上采用了最原生的系统级方案来接管网络流量，做到"无感"和"高效"：

#### 🤖 Android 端
*   **机制**: 使用 Android 原生 **`VpnService`** API。
*   **原理**: App 会创建一个虚拟网卡 (TUN Interface)，系统将所有网络请求转发给这个虚拟网卡。底层通过 **JNI** 调用 C++ 编写的路由核心，将流量拦截并进行规则判断，随后通过加密通道发送至服务器。
*   **优势**: 全局代理能力强，不依赖 Root 权限。

#### 🍎 iOS 端
*   **机制**: 使用 Apple **`NetworkExtension` (Packet Tunnel Provider)** 框架。
*   **原理**: 利用 iOS 系统的沙盒机制，启动一个独立的 VPN 进程 (`PacketTunnelProvider.swift`)。该进程与主 App 隔离，负责在后台持续运行核心转发服务，即使主 App 关闭也能保持连接。
*   **优势**: 极致省电，符合 App Store 上架规范。

#### 💻 桌面端 (Windows / macOS / Linux)
*   **机制**: **System Proxy (系统代理)** + **Sidecar (伴生进程)**。
*   **原理**:
    1.  Flux 启动时，会在后台静默启动一个 V2Ray/Xray 内核进程 (Sidecar)。
    2.  App 自动修改操作系统的 **系统代理设置** (HTTP/SOCKS5)，指向本地内核监听端口 (如 `127.0.0.1:10808`)。
    3.  所有浏览器和支持系统代理的应用流量会自动流向内核。
*   **优势**: 兼容性好，不干扰系统底层驱动。

### 🛠 支持协议 / Supported Protocols

✅ **已验证平台 (Verified on Android & Windows)**:
- **Hysteria2**: [https://v2.hysteria.network/](https://v2.hysteria.network/) (极速抗封锁协议)
- **VLESS** (Vision / Reality)
- **VMess** (TCP / WebSocket)
- **Trojan**
- **Shadowsocks** (AEAD)

⚠️ **注意 / Note**: 
开发者暂无 Apple 设备，**iOS 和 macOS 版本尚未经过完整测试**。欢迎社区贡献测试反馈！
(Developer has no Apple devices to test iOS/macOS builds. Contributions welcome!)

---

## 🌐 OSS 远程配置 (域名下发)

Flux 支持通过 OSS/CDN 下发远程配置，实现 **域名自动切换**、**版本更新通知**、**公告推送** 等功能。

### 配置方法

1. 将以下 JSON 配置文件上传到您的 OSS/CDN（如阿里云 OSS、Cloudflare R2、GitHub Raw 等）
2. 在 `lib/services/remote_config_service.dart` 中配置 `_ossUrls` 列表

### JSON 配置格式

```json
{
  "config_version": 1,
  "domains": [
    "https://api1.example.com/api/v1",
    "https://api2.example.com/api/v1",
    "https://backup.example.com/api/v1"
  ],
  "backup_subscription": "https://backup-sub.example.com/sub",
  
  "announcement": {
    "enabled": true,
    "title": "系统公告",
    "content": "春节期间正常服务，祝大家新年快乐！",
    "type": "info"
  },
  
  "maintenance": {
    "enabled": false,
    "message": "系统维护中，预计2小时后恢复"
  },
  
  "update": {
    "min_version": "1.0.0",
    "latest": {
      "android": { "version": "1.2.0", "url": "https://example.com/flux-1.2.0.apk", "force": false },
      "ios": { "version": "1.2.0", "url": "https://apps.apple.com/app/id123456", "force": false },
      "windows": { "version": "1.2.0", "url": "https://example.com/flux-1.2.0-win.zip", "force": false },
      "macos": { "version": "1.2.0", "url": "https://example.com/flux-1.2.0-mac.dmg", "force": false },
      "linux": { "version": "1.2.0", "url": "https://example.com/flux-1.2.0-linux.tar.gz", "force": false }
    },
    "changelog": "1. 新增 WireGuard 和 TUIC 协议支持\n2. 修复若干 bug"
  },
  
  "contact": {
    "telegram": "https://t.me/your_group",
    "website": "https://yoursite.com"
  },
  
  "features": {
    "invite_enabled": true,
    "purchase_enabled": true,
    "ssr_enabled": false
  },
  
  "recommended_nodes": ["香港01", "日本02"]
}
```

### 字段说明

| 字段 | 说明 |
|------|------|
| `config_version` | 配置版本号，用于判断是否需要更新缓存 |
| `domains` | API 域名列表，按优先级排序，自动测试可用性 |
| `backup_subscription` | 备用订阅地址 |
| `announcement` | 公告配置，`type` 可选 `info`/`warning`/`error` |
| `maintenance` | 维护模式，启用时阻止用户操作 |
| `update` | 版本更新信息，`force: true` 表示强制更新 |
| `min_version` | 最低支持版本，低于此版本强制更新 |
| `contact` | 客服联系方式 |
| `features` | 功能开关 |
| `recommended_nodes` | 推荐节点名称列表 |

---

### 💬 加入社区 / Community

- **Telegram Group**: [https://t.me/+62Otr015kSs1YmNk](https://t.me/+62Otr015kSs1YmNk)

---

### 🚀 快速开始 / Quick Start

### 1. 下载代码

```bash
git clone https://github.com/flux-apphub/flux.git
cd flux
```

### 2. 替换 API 地址 (核心步骤)

打开文件夹 `lib` -> `services` -> `api_config.dart`。
找到下面的代码，把网址改成您自己的面板地址：

```dart
// lib/services/api_config.dart

Future<String> getBaseUrl() async {
  // 👇 只需要改这一行！
  // 例如您的面板是 https://v2board.com，那就填 https://v2board.com/api/v1
  // 注意：一定要保留后面的 /api/v1
  return 'https://您的面板域名.com/api/v1'; 
}
```

### 3. 修改 App ID (必看)

为了确保应用能正常安装且不与他人冲突，请务必在以下文件中将默认的 `com.example.yourapp` 替换为您自己的 App ID (包名)，例如 `com.yourname.project`：

| 平台 | 文件路径 | 修改项 |
|------|---------|--------|
| **Android** | `android/app/build.gradle.kts` | `applicationId` 和 `namespace` |
| **Android** | `android/app/src/main/AndroidManifest.xml` | 检查 package 声明 |
| **iOS** | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` (全局搜索替换) |
| **macOS** | `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_BUNDLE_IDENTIFIER` |
| **Linux** | `linux/CMakeLists.txt` | `APPLICATION_ID` |
| **Windows** | `pubspec.yaml` | `msix_config` 下的 `identity_name` |

> ⚠️ **重要**: 修改 Android 包名后，还需要重命名 `android/app/src/main/kotlin/com/example/yourapp/` 目录结构以匹配新包名。

---

### 4. 修改应用名称

| 平台 | 文件路径 | 修改项 |
|------|---------|--------|
| **Android** | `android/app/src/main/AndroidManifest.xml` | `android:label="您的应用名"` |
| **iOS** | `ios/Runner/Info.plist` | `CFBundleDisplayName` |
| **macOS** | `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME` |
| **Linux** | `linux/CMakeLists.txt` | `set(BINARY_NAME "您的应用名")` |
| **Windows** | `windows/runner/Runner.rc` | `VALUE "ProductName"` 和 `VALUE "FileDescription"` |
| **Windows** | `pubspec.yaml` | `msix_config` 下的 `display_name` |

---

### 5. 替换应用图标 🎨

#### 方法一：使用 flutter_launcher_icons (推荐)

1. 准备一张 **1024x1024** 的 PNG 图片（正方形，无透明背景更佳）
2. 将图片放到 `assets/images/app_icon.png`
3. 确保 `pubspec.yaml` 中已配置：
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.14.4

   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/images/app_icon.png"
     # 移除 alpha 通道 (iOS 要求)
     remove_alpha_ios: true
   ```
4. 运行命令：
   ```bash
   flutter pub run flutter_launcher_icons
   ```

#### 方法二：手动替换

| 平台 | 图标位置 | 说明 |
|------|---------|------|
| **Android** | `android/app/src/main/res/mipmap-*/` | 替换所有尺寸的 `ic_launcher.png` |
| **iOS** | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | 替换所有尺寸的图标文件 |
| **macOS** | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` | 同 iOS |
| **Windows** | `windows/runner/resources/app_icon.ico` | 需要 `.ico` 格式 |
| **Linux** | `assets/icons/app_icon.png` | 或配置 `linux/CMakeLists.txt` |

> 💡 **提示**: 可使用 [https://icon.kitchen](https://icon.kitchen) 或 [https://appicon.co](https://appicon.co) 在线生成各平台所需的图标尺寸。

---

### 6. 其他个性化配置

#### 修改启动页 (Splash Screen)

| 平台 | 文件位置 | 说明 |
|------|---------|------|
| **Android** | `android/app/src/main/res/drawable/splash_icon.xml` | 启动图标 SVG |
| **Android** | `android/app/src/main/res/values/colors.xml` | 启动页背景色 |
| **iOS** | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | 启动图片 |
| **iOS** | `ios/Runner/Base.lproj/LaunchScreen.storyboard` | 启动页布局 |

#### 修改主题颜色

文件: `lib/main.dart` 或 `lib/theme/` 目录
```dart
MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,  // 改为您的品牌色
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  ),
)
```

#### 修改 OSS 远程配置地址

文件: `lib/services/remote_config_service.dart`
```dart
static const List<String> _ossUrls = [
  'https://your-bucket.oss-cn-hangzhou.aliyuncs.com/config.json',
  'https://cdn.example.com/config.json',
];
```

### 7. 开始打包

确保您已安装 Flutter 运行环境。

-   **Android (生成 APK)**:
    ```bash
    flutter build apk --release
    ```
    *产物路径: `build/app/outputs/flutter-apk/app-release.apk`*

-   **iOS (生成 IPA)**:
    ```bash
    flutter build ipa
    ```
    *注意: 需要 macOS 环境及 Apple 开发者账号签名。*
    *产物路径: `build/ios/archive/Runner.xcarchive`*

-   **Windows (生成 exe)**:
    ```bash
    flutter build windows
    ```
    *产物路径: `build/windows/runner/Release/`*

-   **macOS (生成 app)**:
    ```bash
    flutter build macos
    ```
    *产物路径: `build/macos/Build/Products/Release/flux.app`*

-   **Linux (生成可执行文件)**:
    ```bash
    flutter build linux
    ```
    *产物路径: `build/linux/x64/release/bundle/`*

---

## ☕ 请我喝杯咖啡

如果这个项目对您有帮助，欢迎请作者喝杯咖啡，支持开源开发！

| USDT (TRC20) | USDC (Arbitrum) | ETH (Arbitrum) | USDT (ERC20) |
| :---: | :---: | :---: | :---: |
| <img src="assets/images/donation/usdt_trc20.png" width="180" alt="USDT TRC20"> | <img src="assets/images/donation/usdc_arbitrum.png" width="180" alt="USDC Arbitrum"> | <img src="assets/images/donation/eth_arbitrum.png" width="180" alt="ETH Arbitrum"> | <img src="assets/images/donation/usdt_erc20.png" width="180" alt="USDT ERC20"> |

---

## 🔗 相关项目

### 核心代理引擎
-   [Xray-core](https://github.com/XTLS/Xray-core): 本项目使用的核心代理引擎。
-   [V2Ray-core](https://github.com/v2fly/v2ray-core): 经典的代理内核。
-   [Sing-box](https://github.com/SagerNet/sing-box): 通用代理平台。
-   [Hysteria](https://github.com/apernet/hysteria): 强大的抗封锁代理协议。

### 面板 & 管理
-   [V2Board](https://github.com/wyx2685/v2board): 强大的 V2Ray 面板。

### 工具 & 库
-   [hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel): 高性能 SOCKS5 隧道。
-   [geoip](https://github.com/Loyalsoldier/geoip): GeoIP 数据库。
-   [domain-list-community](https://github.com/v2fly/domain-list-community): 域名分流规则。

### 其他客户端参考
-   [v2rayNG](https://github.com/2dust/v2rayNG): Android V2Ray 客户端。
-   [V2RayXS](https://github.com/tzmax/V2RayXS): macOS V2Ray 客户端。
-   [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid): 多协议代理客户端。

---

**Flux Open Source** - Make Connection Simple.
