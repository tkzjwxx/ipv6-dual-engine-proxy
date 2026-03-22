# 🚀 Dual-Track Tri-Body Matrix V1.4 / 极简双轨三体矩阵系统 V1.4

[English](#english) | [简体中文](#chinese)

---

<h2 id="english">🇺🇸 English</h2>

A highly advanced, commercial-grade Proxy Matrix specifically tailored for pure IPv6 VPS (like Woiden, Hax). 

Version 1.4 introduces the **"Dual-Track Tri-Body"** architecture. It splits traffic into two completely physically isolated outbound tracks (Native IPv6 & WARP IPv4) and runs three core protocols (HY2, VLESS, VMess) on each, giving you 6 independent channels managed by a unified interactive dashboard.

### ⚙️ Core Architecture (6 Channels)
* **🚄 Track A: Native IPv6 Direct Bus (Max Speed)**
  * Bypasses WARP entirely. Binds to the host's native IPv6 network card.
  * *Channels*: **HY2** (Port 8443) | **VLESS via Argo** (Port 10001) | **VMess via Argo** (Port 10002)
  * *Use Case*: Uncapped speeds for IPv6-supported sites (YouTube 4K, Netflix, Google).
* **🛸 Track B: WARP IPv4 Compatible Bus (Max Compatibility)**
  * Forwards all traffic through the Cloudflare WARP IPv4 NAT interface.
  * *Channels*: **HY2** (Port 8444) | **VLESS via Argo** (Port 10003) | **VMess via Argo** (Port 10004)
  * *Use Case*: 100% compatibility for IPv4-only websites and excellent IP unlocking capabilities.

### ✨ Epic V1.4 Features
* **The `st` System Terminal**: All scattered commands (`v`, `c`, `w`, `u`) are now unified into a single interactive dashboard. Just type `st`.
* **Dynamic Hibernation Switches**: Don't need all 6 channels? Turn them off in the `st` menu! The system uses `jq` to dynamically slice the JSON config and perform a lossless hot-reload. Unused ports vanish physically, saving RAM and preventing port scanning.
* **TCP WARP Watchdog**: A zero-overhead, pure-IP background probe (`http://1.1.1.1/cdn-cgi/trace`). It avoids DNS pollution and ICMP drops, executing a silent WARP resuscitation only when a true deadlock is detected.
* **Smart Argo Deployment**: Paste the entire Cloudflare installation command, and the system's regex engine will auto-extract the core token.

### 🚀 Quick Install
Run the following chained command in your terminal as `root`:

```bash
echo -e "nameserver 2606:4700:4700::1111\nnameserver 2001:4860:4860::8888" > /etc/resolv.conf; sed -i '/virtuozzo/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; apt-get update -y; apt-get install -y curl; bash <(curl -sSL https://cdn.jsdelivr.net/gh/tkzjwxx/ipv6-dual-engine-proxy@main/install.sh)
```
*(⚠️ Note: During installation, the WARP menu will pop up. Follow the prompts to get an IPv4 address, then type `0` to exit the menu and let the Matrix deployment finish automatically!)*

---

<h2 id="chinese">🇨🇳 简体中文</h2>

专为纯 IPv6 VPS（如 Woiden、Hax）量身定制的商业级出站生态系统。

V1.4 版本迎来了史诗级的**“双轨三体矩阵”**重构！系统在底层出站路由上，强行劈开“原生 IPv6”与“WARP IPv4”两条互不干扰的物理总线，并在每条总线上挂载 HY2、VLESS、VMess 三大协议，为您提供 6 个绝对纯粹的独立节点，并由大一统中控台统一调度。

### ⚙️ 核心架构 (双轨六通道)
* **🚄 A 轨：原生 IPv6 极速直通总线 (速度之王)**
  * 强制绑定宿主机原生 IPv6 物理网卡，打死不碰 WARP。
  * *通道分配*：**HY2** (公网:8443) | **VLESS 优选** (Argo:10001) | **VMess 常规** (Argo:10002)
  * *核心优势*：访问 YouTube 4K、Netflix 等支持 IPv6 的网站时，流量直接走跨海光缆原路起飞，享受 0 代理损耗的满血原生速度！
* **🛸 B 轨：WARP IPv4 兼容穿透总线 (全能战士)**
  * 强制将流量送入 Cloudflare WARP 虚拟网卡隧道。
  * *通道分配*：**HY2** (公网:8444) | **VLESS 优选** (Argo:10003) | **VMess 常规** (Argo:10004)
  * *核心优势*：通杀全网 100% 的网站（涵盖仅支持 IPv4 的老旧站点），自带优质原生 IP 解锁属性。

### ✨ V1.4 史诗级黑科技
* **大一统中控大厅 (`st`)**：抛弃过去所有零散的单字母指令。现在，只需在终端敲下 `st`，即可唤出极客感拉满的全局交互大盘。
* **物理级动态休眠阀门**：嫌 6 个节点太多？直接在面板里输入序号关掉它！系统会利用 `jq` 手术刀动态切除对应的 JSON 配置并无损热重载。休眠节点连 1KB 内存都不会占用，端口彻底消失，真正做到“安安静静”与防扫描。
* **纯 IP 无感 TCP 守护犬**：摒弃了耗资源的哪吒探针和容易引发假阳性误杀的 ICMP (Ping) 探针。独创底层 HTTP/TCP 探针直连 CF 骨干网，零 DNS 负担。WARP 一旦死锁，后台秒级执行心肺复苏。
* **Argo 智能正则截获**：部署 CF 隧道时，你可以直接把网页上的一大长串安装代码全粘进去，底层的正则引擎会自动帮你把 Token 扒出来，实现真正的傻瓜式操作。

### 🚀 创世部署指令
请使用 `root` 用户在终端执行以下链式命令（自带极其严苛的环境清理与 DNS 修复）：

```bash
echo -e "nameserver 2606:4700:4700::1111\nnameserver 2001:4860:4860::8888" > /etc/resolv.conf; sed -i '/virtuozzo/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; apt-get update -y; apt-get install -y curl; bash <(curl -sSL https://cdn.jsdelivr.net/gh/tkzjwxx/ipv6-dual-engine-proxy@main/install.sh)
