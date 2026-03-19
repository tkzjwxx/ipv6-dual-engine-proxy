# 🚀 IPv6 Dual-Engine Proxy Stack / 极简双擎出站系统

[English](#english) | [简体中文](#chinese)

---

<h2 id="english">🇺🇸 English</h2>

A **Minimal Dual-Engine Proxy System** tailored specifically for pure IPv6 VPS (like Woiden, Hax). 

It seamlessly integrates **WARP-GO** (for IPv4 outbound) and **Sing-box** (as the core forwarder) to provide blazing-fast Hysteria2 direct connections and stealthy VMess tunnels via Cloudflare Argo.

### ⚙️ Core Architecture
* **Outbound Engine**: WARP-GO (Unlocks IPv4 access for pure IPv6 machines).
* **Forwarding Core**: Sing-box (Lightweight, high-performance).
* **Inbound Channels**: 
  * ⚡ `Hysteria2`: Binds to IPv6 `::` (Port 8443) for raw, high-speed direct connections.
  * 🛡️ `VMess + WS`: Binds to localhost `127.0.0.1:10001`, ready to be proxied seamlessly by Cloudflare Argo Tunnel.

### ✨ Highlights
Five incredibly simple **single-letter global shortcuts** for management:
* `v` - Show connection links (HY2 & VMess) and Argo Tunnel setup guide.
* `c` - Real-time system status dashboard.
* `w` - Quick access to the WARP menu.
* `r` - View Sing-box real-time logs.
* `u` - One-click complete uninstallation (Self-destruct).

### 🚀 Quick Install
Run the following command in your terminal as `root`:

```bash
bash <(curl -sL [https://raw.githubusercontent.com/tkzjwxx/ipv6-dual-engine-proxy/main/install.sh](https://raw.githubusercontent.com/tkzjwxx/ipv6-dual-engine-proxy/main/install.sh))
```
*(⚠️ Note: During installation, the WARP menu will pop up. Follow the prompts to get an IPv4 address, then type `0` to exit the menu and continue the deployment.)*

---

<h2 id="chinese">🇨🇳 简体中文</h2>

专为纯 IPv6 VPS（如 Woiden、Hax）量身定制的**极简双擎代理出站系统**。

完美融合 **WARP-GO**（提供纯净 IPv4 出口）与 **Sing-box**（核心流媒体转发），为您同时提供极速的 Hysteria2 原生直连节点与高隐蔽性的 VMess (Argo) 备用隧道。

### ⚙️ 核心架构
* **出站引擎**：WARP-GO（彻底解决纯 IPv6 机器无 IPv4 访问权限的痛点）。
* **转发核心**：Sing-box（极致轻量、性能拉满）。
* **入站双通道**：
  * ⚡ `Hysteria2`：绑定公网 IPv6 端口 `8443`，利用 UDP 协议提供无惧丢包的极速直通体验。
  * 🛡️ `VMess + WS`：绑定本地回环端口 `127.0.0.1:10001`，专为 Cloudflare Argo Tunnel 内网穿透设计，即使 IP 被封也能满血复活。

### ✨ 极致交互体验
告别难记的长命令，独创 **5 大单字母全局快捷键**：
* `v` 提取节点配置（包含完整的 Argo 穿透零门槛设置指南）。
* `c` 唤出监控大盘（一秒看清 Sing-box、Argo、WARP 运行状态）。
* `w` 呼出 WARP 面板（随时切换、重置出站 IP）。
* `r` 实时滚动日志（精准排错查漏）。
* `u` 彻底自毁卸载（不留一丝痕迹，还你纯净系统）。

### 🚀 一键部署指令
请使用 `root` 用户在终端执行以下命令：

```bash
bash <(curl -sL [https://raw.githubusercontent.com/tkzjwxx/ipv6-dual-engine-proxy/main/install.sh](https://raw.githubusercontent.com/tkzjwxx/ipv6-dual-engine-proxy/main/install.sh))
```
*(⚠️ 交互提示：脚本运行中途会呼出勇哥的 WARP 菜单，请按照屏幕提示安装 WARP 并成功获取 IPv4 后，输入 `0` 退出菜单，脚本将自动接力完成剩余的 Sing-box 部署！)*

---
