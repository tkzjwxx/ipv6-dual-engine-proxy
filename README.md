# -ipv6-VPS-
HY2+VMESS AGRO 双协议搭建
# 🚀 纯 IPv6 VPS 极简双擎出站系统


apt-get update -y && apt-get install -y curl wget && sed -i '/virtuozzo/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null ; bash <(curl -sL https://raw.githubusercontent.com/tkzjwxx/-ipv6-VPS-/main/install.sh)

---

## ✨ 核心特性

* **🌍 WARP-GO 赋予全网访问**：自动部署并接管 IPv4 出站路由，解决纯 IPv6 机器无法访问外网的痛点。
* **⚡ Hysteria2 原生直连**：监听公网 IPv6，利用高并发特性提供极致的直连速度。
* **🛡️ VMess + Argo 绝对隐身**：VMess 节点仅监听本地 `127.0.0.1:10001`，不对外暴露任何端口，配合 Cloudflare Tunnel 实现真正的内网穿透与防封锁。
* **⌨️ 全局快捷键管理**：摒弃繁琐的 Linux 命令，通过 5 个极简字母命令掌控全局。

---

## 🛠️ 一键部署命令

在新重置的空白纯 IPv6 机器上，**无需提前安装 curl**，直接复制以下引导命令在终端执行即可：

```bash
apt-get update -y && apt-get install -y curl wget && sed -i '/virtuozzo/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null ; bash <(curl -sL [https://raw.githubusercontent.com/tkzjwxx/-ipv6-VPS-/main/install.sh](https://raw.githubusercontent.com/tkzjwxx/-ipv6-VPS-/main/install.sh))

专为纯 IPv6 VPS（如 HAX、Woiden）打造的极简、纯粹、高并发数据转发中枢。通过 WARP 提供 IPv4 访问能力，结合 Hysteria2 直连与 VMess Argo 隧道，实现速度与安全的双重保障。

---

## ✨ 核心特性

* **🌍 WARP-GO 赋予全网访问**：自动部署并接管 IPv4 出站路由，解决纯 IPv6 机器无法访问外网的痛点。
* **⚡ Hysteria2 原生直连**：监听公网 IPv6，利用高并发特性提供极致的直连速度。
* **🛡️ VMess + Argo 绝对隐身**：VMess 节点仅监听本地 `127.0.0.1:10001`，不对外暴露任何端口，配合 Cloudflare Tunnel 实现真正的内网穿透与防封锁。
* **⌨️ 全局快捷键管理**：摒弃繁琐的 Linux 命令，通过 5 个极简字母命令掌控全局。

---

## 🛠️ 一键部署命令

在新重置的空白纯 IPv6 机器上，**无需提前安装 curl**，直接复制以下引导命令在终端执行即可：

```bash
apt-get update -y && apt-get install -y curl wget && sed -i '/virtuozzo/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null ; bash <(curl -sL [https://raw.githubusercontent.com/tkzjwxx/-ipv6-VPS-/main/install.sh](https://raw.githubusercontent.com/tkzjwxx/-ipv6-VPS-/main/install.sh))

脚本运行期间会自动挂起并呼出勇哥的 WARP 菜单，请手动选择安装 WARP 单栈 IPv4 或双栈。看到成功获取到 WARP IP 后，输入 0 退出菜单，天网主程序会自动接力完成剩余部署。



快捷键功能说明详细描述v🔗 提取节点与指南一键生成 HY2 直连节点与 VMess 节点链接，并附带 Argo 隧道映射配置参数说明。c📊 状态大盘极简表格视图，一秒查看 Sing-box、Argo 隧道进程状态及 WARP 出站连通性。w🌐 WARP 管理直通 WARP-GO 脚本菜单，方便后续重置 IP、切换节点或检查出站状态。r📜 实时日志实时滚动打印 Sing-box 核心运行日志，方便排查连接故障（按 Ctrl+C 退出）。u💥 物理级自毁一键停用并彻底删除 Sing-box、Argo 及 WARP 组件，将机器恢复至纯净初始状态。
