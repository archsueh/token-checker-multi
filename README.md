# Token Checker Multi / 多服务增强版


**中文**  
一个增强版的 macOS 菜单栏工具，支持 Claude Code、Codex 和 Grok 的使用率实时监控。菜单栏仅显示使用率最高的单个甜甜圈，点击后展开完整纵向列表查看所有服务详情。

**English**  
An enhanced macOS menu bar app for real-time usage monitoring of Claude Code, Codex, and Grok. The menu bar shows only a single donut for the highest-usage service; click to expand a full vertical list with details for all services.

<img width="395" height="537" alt="截屏2026-05-29 晚上9 53 32" src="https://github.com/user-attachments/assets/f836489e-cde9-4527-ae84-a6525944f664" />

---

## 原项目简介（保留日文 / Original Japanese Introduction）

このリポジトリは、[otoha1119/token-checker](https://github.com/otoha1119/token-checker) をベースに大幅に拡張したフォーク版です。

元のプロジェクトは以下の通りです：

> macOS のメニューバーに Claude Code と Codex の使用率を常時表示する macOS アプリケーション。

ターミナルで `claude login` / `codex login` を完了済みのアカウントに対し、Anthropic の OAuth エンドポイントおよび `codex app-server` の JSON-RPC を経由してレート制限情報を取得する。取得結果はメニューバーに 2 個のドーナツチャートと数値で表示され、クリックでポップオーバーに 5 時間ウィンドウと週次ウィンドウの詳細を展開する。

---

## 主要改动 / Key Modifications

**中文**  
- 新增 Grok 支持：通过读取 `~/.grok/auth.json` 获取使用率信息
- 移除 Gemini 支持（使用频率较低，暂不维护）
- UI 大幅优化：菜单栏仅显示一个甜甜圈（当前使用率最高的服务）
- 点击菜单栏图标后，以纵向列表形式展示全部服务详情
- 支持三个服务：Claude Code、Codex、Grok

**English**  
- Added Grok support (reads from `~/.grok/auth.json`)
- Removed Gemini support (low usage frequency)
- Major UI improvement: menu bar now shows only one donut (the service with highest current usage)
- Clicking the menu bar icon opens a clean vertical list showing details for all services
- Currently supports three services: Claude Code, Codex, and Grok

---

## 功能特点 / Features

**中文**  
- 菜单栏常驻显示最高使用率服务的甜甜圈 + 百分比
- 点击展开后可查看各服务的 5 小时窗口和周窗口使用率
- 支持自动刷新（可调节间隔）
- 支持开机自启动
- 基于原项目优秀架构，扩展性良好

**English**  
- Menu bar always shows a single donut + percentage of the most constrained service
- Click to expand and view 5-hour and weekly usage windows for each service
- Configurable auto-refresh interval
- Supports launch at login
- Built on the solid architecture of the original project with good extensibility

---

## 动作要件 / Requirements

| 项目 / Item          | 值 / Value                                      |
|----------------------|-------------------------------------------------|
| macOS                | 14 Sonoma 及以上 / 14 Sonoma or later           |
| Swift                | 5.9 及以上（Xcode Command Line Tools 即可）     |
| Claude Code CLI      | 已执行 `claude login`                           |
| Codex CLI            | 已执行 `codex login`                            |
| Grok CLI (可选)      | 已安装并登录 `~/.grok/bin/grok`                 |

**中文**：三个服务中任意缺少都不会影响其他服务的正常工作。

**English**: The absence of any service does not affect the functionality of the others.

---

## 安装 / Installation

**中文**  
克隆本仓库后，在本地构建并安装：

```bash
./Scripts/build.sh --install
```

构建时若未找到 Apple Development 签名身份，将自动使用 ad-hoc 签名。你构建的 `.app` 可直接运行。

安装完成后，可从 Finder 的「应用程序」文件夹打开 `TokenChecker`，或执行：

```bash
open /Applications/TokenChecker.app
```

**English**  
Clone this repository and build on your machine:

```bash
./Scripts/build.sh --install
```

If no Apple Development signing identity is found, ad-hoc signing will be used automatically. The built `.app` can be launched directly.

After installation, open `TokenChecker` from the Applications folder, or run:

```bash
open /Applications/TokenChecker.app
```

---

## 使用方法 / Usage

**中文**  
首次使用前，请在终端分别登录对应服务：

```bash
claude login
codex login
~/.grok/bin/grok login     # 如需使用 Grok
```

登录后 token 会保存在 Keychain 或 `~/.grok/auth.json` 中，应用会自动读取。

**English**  
Before first use, log in to the services via terminal:

```bash
claude login
codex login
~/.grok/bin/grok login     # For Grok support
```

Tokens are saved to Keychain or `~/.grok/auth.json`. The app reads them automatically.

---

## 数据获取方式 / Data Sources

**中文**  
- **Claude Code**: 通过 Keychain 读取 OAuth Token，调用 Anthropic 官方 usage 接口
- **Codex**: 启动 `codex app-server` 子进程，通过 JSON-RPC 获取速率限制
- **Grok**: 读取 `~/.grok/auth.json` 中的 JWT Token，解析使用情况（当前基于 tier 的实现）

**English**  
- **Claude Code**: Reads OAuth token from Keychain and calls Anthropic’s official usage endpoint
- **Codex**: Spawns `codex app-server` subprocess and queries rate limits via JSON-RPC
- **Grok**: Reads JWT from `~/.grok/auth.json` and parses usage information (currently tier-based)

---

## 卸载 / Uninstall

```bash
killall TokenChecker
defaults delete com.token-checker.app 2>/dev/null
rm -rf /Applications/TokenChecker.app
```

---

## 许可证 / License

本软件基于 [MIT License](./LICENSE) 发布。

原项目作者：otoha1119  
本增强版由 ArcHsueh 维护。

"Anthropic", "Claude", "Codex", "Grok" 均为各自公司的商标。本软件与上述公司无关，亦未获得其认可。

---

## 免责声明 / Disclaimer

本软件按“现状”提供，不提供任何形式的明示或暗示保证。使用本软件所产生的任何后果（包括但不限于数据丢失、账户限制、隐私泄露等），作者概不负责。请自行承担使用风险。

---

## 致谢 / Acknowledgments

- 原项目 UI 设计参考了 [s-age/ccmeter](https://github.com/s-age/ccmeter)（MIT License）
- 感谢原作者 otoha1119 提供的优秀基础框架
- Grok 支持参考了 xAI Grok CLI 的认证机制

---

## 贡献 / Contributing

欢迎提交 Issue 和 Pull Request，共同改进对 Grok 等新服务的支持。

---

**项目地址**  
https://github.com/ArcHsueh/token-checker-multi

原项目：https://github.com/otoha1119/token-checker
