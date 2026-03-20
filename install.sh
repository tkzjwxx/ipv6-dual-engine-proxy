#!/bin/bash
# ====================================================================
# 极简双擎出站系统 V1.1 (纯 IPv6 机器专供 | Argo全自动 + 资源大盘版)
# 核心组件：WARP-GO (IPv4出站) + Sing-box (HY2 直连 + VMess 隧道本地端)
# ====================================================================
echo -e "\033[1;36m🚀 正在执行【极简双擎出站系统 V1.1】初始化...\033[0m"

# 1. 环境清理与依赖补全
systemctl stop sing-box w_master warp-go cloudflared 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/v /usr/bin/w /usr/bin/r /usr/bin/u /usr/bin/a
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget jq openssl cron nano coreutils >/dev/null 2>&1
mkdir -p /etc/s-box

# 2. 网络干预：解决拉取 GitHub/Gitlab 时 wget 假死
echo "prefer-family = IPv6" > ~/.wgetrc
sed -i '/precedence ::ffff:0:0\/96  10/d' /etc/gai.conf 2>/dev/null

# ====================================================================
# 3. 部署 WARP (提供 IPv4 出口)
# ====================================================================
echo -e "\n\033[1;32m🌐 第一阶段：呼出勇哥 WARP 菜单，获取 IPv4...\033[0m"
rm -f /root/CFwarp.sh
curl -sL -o /root/CFwarp.sh https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh
chmod +x /root/CFwarp.sh
echo -e "\033[1;33m⚠️ 请手动安装 (建议双栈 或 单栈IPv4)，看到成功获取 WARP IP 后输入 0 退出！\033[0m"
sleep 3
bash /root/CFwarp.sh

echo -e "\n\033[1;33m⏳ 正在校验 WARP IPv4 连通性...\033[0m"
V4_READY=false
for i in {1..5}; do
    WARP_IP=$(curl -s4 -m 5 api.ipify.org 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
    if [ -n "$WARP_IP" ]; then
        echo -e "\033[1;32m✅ WARP IPv4 引擎握手成功！出口 IP: $WARP_IP\033[0m"
        V4_READY=true
        break
    else
        echo -e "\033[1;35m⚠️ 未检测到 IPv4，等待 WARP 路由生效中...\033[0m"; sleep 5
    fi
done
if [ "$V4_READY" = false ]; then
    echo -e "\n\033[1;41;37m 💀 WARP 未获取到 IPv4！无法提供出站，部署中止。\033[0m"
    exit 1
fi

# ====================================================================
# 4. 部署 Sing-box (核心转发引擎 - 真七层嗅探)
# ====================================================================
echo -e "\n\033[1;33m📦 第二阶段：拉取 Sing-box 核心...\033[0m"
S_URL=$(curl -sL --connect-timeout 5 -A "Mozilla/5.0" "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -o 'https://[^"]*linux-amd64\.tar\.gz' | head -n 1)
[ -z "$S_URL" ] && S_URL="https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz"
curl -sL --connect-timeout 15 -o /tmp/sbox.tar.gz "$S_URL"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ 2>/dev/null
mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box 2>/dev/null
chmod +x /etc/s-box/sing-box

# 生成证书与底层配置
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null

cat << 'EOF' > /etc/s-box/sing-box.json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    { "type": "hysteria2", "tag": "hy2-in", "listen": "::", "listen_port": 8443, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"}, "sniff": true, "sniff_override_destination": true },
    { "type": "vmess", "tag": "vmess-in", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/argo"}, "sniff": true, "sniff_override_destination": true }
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct-out" }
  ],
  "route": {
    "rules": [
      { "inbound": ["hy2-in", "vmess-in"], "outbound": "direct-out" }
    ]
  }
}
EOF

cat > /etc/systemd/system/sing-box.service << 'EOF'
[Unit]
Description=Sing-box Core Service
After=network.target
[Service]
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
LimitNOFILE=512000
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now sing-box >/dev/null 2>&1

# ====================================================================
# 5. 写入 6 大极简管理快捷键
# ====================================================================

# [a] Argo 一键部署引擎
cat << 'EOF' > /usr/bin/a
#!/bin/bash
clear
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;32m   ☁️  Argo 隧道全自动部署引擎 (Cloudflared)\033[0m"
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;33m👉 准备工作：请前往 Cloudflare 网页端创建 Tunnel，将流量指向 localhost:10001\033[0m"
echo -e "\033[1;37m(请从网页提供的安装命令中，提取出一长串以 eyJ 开头的 Token 字符)\033[0m"
echo ""
read -p "🔑 请在此粘贴你的 Token: " ARGO_TOKEN

if [[ -z "$ARGO_TOKEN" || "$ARGO_TOKEN" != eyJ* ]]; then
    echo -e "\n\033[1;31m❌ 致命错误：Token 格式不正确或为空！它必须以 eyJ 开头。\033[0m"
    exit 1
fi

echo -e "\n\033[1;35m⏳ 正在拉取官方 cloudflared 核心，请稍候...\033[0m"
systemctl stop cloudflared 2>/dev/null
rm -f /usr/local/bin/cloudflared /etc/systemd/system/cloudflared.service 2>/dev/null
curl -sL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x /usr/local/bin/cloudflared

echo -e "\033[1;35m⚙️ 正在向宿主机注册并启动 Argo 系统服务...\033[0m"
/usr/local/bin/cloudflared service install "$ARGO_TOKEN" >/dev/null 2>&1
systemctl enable --now cloudflared >/dev/null 2>&1
sleep 4

if systemctl is-active --quiet cloudflared || pgrep -x "cloudflared" >/dev/null; then
    echo -e "\n\033[1;32m🎉 部署大捷！Argo 隧道已在此机器上永久驻留并运行。\033[0m"
    echo -e "\033[1;36m👉 请在终端输入 \033[1;33mc\033[1;36m 查看状态大盘确认连通性！\033[0m"
else
    echo -e "\n\033[1;31m💀 部署失败！请检查系统网络或 Token 是否有效。\033[0m"
fi
EOF

# [v] 节点链接生成 (更新为提示自动安装)
cat << 'EOF' > /usr/bin/v
#!/bin/bash
IP=$(curl -s6 -m 5 api64.ipify.org 2>/dev/null || curl -s6 -m 5 icanhazip.com 2>/dev/null || curl -s6 -m 5 ident.me 2>/dev/null)
[ -z "$IP" ] && IP=$(ip -6 addr show dev eth0 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | head -n 1)
[ -z "$IP" ] && IP="[IPv6获取失败_请手动替换]"
W_IP=$(curl -s4 -m 5 api.ipify.org 2>/dev/null)
UUID="d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a"
PW="PsiphonUS_2026"
clear
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;32m🎉 极简双擎系统 - 节点配置指引\033[0m"
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;34m[当前 WARP 出站 IPv4]:\033[0m \033[1;37m${W_IP:-未连接}\033[0m\n"

echo -e "\033[1;35m【一】直连 Hysteria2 节点 (IPv6 原生极速直通保底)\033[0m"
echo -e "\033[40;32m hysteria2://$PW@[$IP]:8443/?sni=bing.com&insecure=1#Direct-HY2 \033[0m\n"

echo -e "\033[1;35m【二】Argo 隧道 VMess 节点 (隐蔽防封出站)\033[0m"
json="{\"v\":\"2\",\"ps\":\"Argo-VMess\",\"add\":\"你的专属CF子域名\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"你的专属CF子域名\",\"path\":\"/argo\",\"tls\":\"tls\"}"
echo -e "\033[40;32m vmess://$(echo -n "$json" | base64 -w 0) \033[0m\n"

echo -e "\033[1;33m💡 提示：如果你还没有启动 Argo 隧道守护进程，\033[0m"
echo -e "\033[1;33m👉 请在终端输入 \033[1;36ma\033[1;33m 唤出全自动部署向导！\033[0m"
echo -e "\033[1;36m=================================================================\033[0m"
EOF

# [c] 状态大盘 (增加系统物理探针与强迫症排版)
cat << 'EOF' > /usr/bin/c
#!/bin/bash
clear
echo -e "\033[1;36m==================================================================\033[0m"
echo -e "\033[1;37m                   🛡️ 极简出站系统监控大盘 V1.1                   \033[0m"
echo -e "\033[1;36m==================================================================\033[0m"

# 宿主机资源物理探针 (防超售卡死)
MEM=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }' 2>/dev/null || echo "未知")
CPU=$(top -bn1 2>/dev/null | grep load | awk '{printf "%.2f", $(NF-2)}' || echo "未知")
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
echo -e "\033[1;34m💻 [宿主状态]\033[0m 持续运行: \033[1;37m${UPTIME:-未知}\033[0m | CPU负载: \033[1;37m$CPU\033[0m | 内存: \033[1;37m$MEM\033[0m"
echo "------------------------------------------------------------------"
echo -e " 组件名称         | 运行状态   | 核心信息"
echo "------------------------------------------------------------------"

# Sing-box 探测
if systemctl is-active --quiet sing-box; then S_C="\033[1;32m"; S_T="🟢运行中"; else S_C="\033[1;31m"; S_T="🔴已停止"; fi
printf " %-14s | ${S_C}%-8s\033[0m | %s\n" "Sing-box 核心" "$S_T" "公网:8443(HY2) 局域:10001"

# Cloudflared 探测
if systemctl is-active --quiet cloudflared || pgrep -x "cloudflared" >/dev/null; then C_C="\033[1;32m"; C_T="🟢已连接"; else C_C="\033[1;33m"; C_T="🟡未运行"; fi
printf " %-14s | ${C_C}%-8s\033[0m | %s\n" "Argo 隧道" "$C_T" "Cloudflare 内网穿透守护中"

# WARP 探测 (增加严谨的超时处理)
W_IP=$(curl -s4 -m 3 api.ipify.org 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
if [ -n "$W_IP" ]; then W_C="\033[1;32m"; W_T="🟢畅通"; W_INFO="IPv4: $W_IP"; else W_C="\033[1;31m"; W_T="🔴断联"; W_INFO="等待路由握手或出口故障"; fi
printf " %-14s | ${W_C}%-8s\033[0m | %s\n" "WARP 出口" "$W_T" "$W_INFO"

echo -e "\033[1;36m==================================================================\033[0m"
EOF

# [w] WARP 直通车
cat << 'EOF' > /usr/bin/w
#!/bin/bash
if [ -f "/root/CFwarp.sh" ]; then bash /root/CFwarp.sh; else echo "⚠️ WARP 脚本文件丢失"; fi
EOF

# [r] 实时日志
cat << 'EOF' > /usr/bin/r
#!/bin/bash
echo -e "\033[1;36m📜 正在跟踪 Sing-box 实时日志 (按 Ctrl+C 退出)...\033[0m\n"
journalctl -u sing-box --no-pager --output cat -f -n 50
EOF

# [u] 自毁卸载 (增加针对 cloudflared 的物理级抹除)
cat << 'EOF' > /usr/bin/u
#!/bin/bash
clear; echo -e "\033[1;31m⚠️ 正在卸载核心组件...\033[0m"
systemctl stop sing-box cloudflared warp-go 2>/dev/null
systemctl disable sing-box cloudflared 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/v /usr/bin/w /usr/bin/r /usr/bin/u /usr/bin/a /etc/systemd/system/sing-box.service
# 物理超度手动安装的 cloudflared
rm -f /usr/local/bin/cloudflared /etc/systemd/system/cloudflared.service 2>/dev/null
systemctl daemon-reload
echo -e "\033[1;33m👉 正在唤出 WARP 菜单，请选择卸载 WARP\033[0m"
[ -f "/root/CFwarp.sh" ] && bash /root/CFwarp.sh
rm -f /root/CFwarp.sh
sed -i '/prefer-family = IPv6/d' ~/.wgetrc 2>/dev/null
echo "🎉 物理超度完毕！机器已恢复纯净状态。"
EOF

chmod +x /usr/bin/v /usr/bin/c /usr/bin/w /usr/bin/r /usr/bin/u /usr/bin/a
echo -e "\n\033[1;32m🎉 极简双擎系统 V1.1 部署完毕！\033[0m"
echo -e "\033[1;37m👉 录入隧道：输入 \033[1;36ma\033[1;37m 一键部署 Argo。\033[0m"
echo -e "\033[1;37m👉 提取节点：输入 \033[1;36mv\033[1;37m 提取双端直连/代理节点。\033[0m"
echo -e "\033[1;37m👉 监控系统：输入 \033[1;36mc\033[1;37m 查看状态与资源大盘。\033[0m"
