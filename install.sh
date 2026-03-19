#!/bin/bash
# ====================================================================
# 极简双擎出站系统 (纯 IPv6 机器专供版)
# 核心组件：WARP-GO (IPv4出站) + Sing-box (HY2 直连 + VMess 隧道本地端)
# ====================================================================
echo -e "\033[1;36m🚀 正在执行【极简双擎出站系统】初始化...\033[0m"

# 1. 环境清理与依赖补全
systemctl stop sing-box w_master warp-go 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/v /usr/bin/w /usr/bin/r /usr/bin/u
apt-get install -y curl wget jq openssl cron nano >/dev/null 2>&1
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
# 4. 部署 Sing-box (核心转发引擎)
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
    { "type": "hysteria2", "tag": "hy2-in", "listen": "::", "listen_port": 8443, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "vmess", "tag": "vmess-in", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/argo"} }
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
# 5. 写入 5 大极简管理快捷键
# ====================================================================

# [v] 节点链接生成与 Argo 指南
cat << 'EOF' > /usr/bin/v
#!/bin/bash
IP=$(curl -s6 -m 5 api64.ipify.org 2>/dev/null || curl -s6 -m 5 icanhazip.com 2>/dev/null)
[ -z "$IP" ] && IP=$(ip -6 addr show dev eth0 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | head -n 1)
[ -z "$IP" ] && IP="[IPv6获取失败]"
W_IP=$(curl -s4 -m 5 api.ipify.org 2>/dev/null)
UUID="d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a"
PW="PsiphonUS_2026"
clear
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;32m🎉 极简双擎系统 - 节点配置与 Cloudflare 隧道指引\033[0m"
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;34m[当前 WARP 出站 IPv4]:\033[0m \033[1;37m${W_IP:-未连接}\033[0m\n"

echo -e "\033[1;35m【一】直连 Hysteria2 节点 (IPv6 原生直通)\033[0m"
echo -e "\033[0m hysteria2://$PW@[$IP]:8443/?sni=bing.com&insecure=1#Direct-HY2"

echo -e "\n\033[1;35m【二】Argo 隧道 VMess 节点 (隐蔽防封)\033[0m"
json="{\"v\":\"2\",\"ps\":\"Argo-VMess\",\"add\":\"你的专属CF子域名\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"你的专属CF子域名\",\"path\":\"/argo\",\"tls\":\"tls\"}"
echo -e "\033[0m vmess://$(echo -n "$json" | base64 -w 0)"

echo -e "\n\033[1;35m【三】自行配置 Argo 隧道 (cloudflared) 步骤\033[0m"
echo -e "1. 网页端创建 Tunnel，绑定子域名 (如 \033[1;33mproxy.yourdomain.com\033[0m)。"
echo -e "2. Service Type 选择 \033[1;37mHTTP\033[0m，URL 填写 \033[1;32mlocalhost:10001\033[0m。"
echo -e "3. 复制 CF 网页上提供的 \033[1;36mcloudflared service install eyJ...\033[0m 命令，在当前终端粘贴运行即可！"
echo -e "\033[1;36m=================================================================\033[0m"
EOF

# [c] 状态大盘
cat << 'EOF' > /usr/bin/c
#!/bin/bash
clear
echo -e "\033[1;36m========================================================\033[0m"
echo -e "\033[1;37m                 🛡️ 极简出站系统监控大盘                 \033[0m"
echo -e "\033[1;36m========================================================\033[0m"
printf "%-18s | %-12s | %s\n" "组件名称" "运行状态" "核心信息"
echo "--------------------------------------------------------"
if systemctl is-active --quiet sing-box; then S_ST="\033[1;32m🟢运行中\033[0m"; else S_ST="\033[1;31m🔴已停止\033[0m"; fi
printf "%-18s | %-21s | %s\n" "Sing-box 核心" "$S_ST" "端口: 8443(公网), 10001(本地)"

if pgrep -x "cloudflared" >/dev/null; then C_ST="\033[1;32m🟢已连接\033[0m"; else C_ST="\033[1;33m🟡未运行\033[0m"; fi
printf "%-18s | %-21s | %s\n" "Argo 隧道" "$C_ST" "Cloudflare 内网穿透守护"

W_IP=$(curl -s4 -m 3 api.ipify.org 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
if [ -n "$W_IP" ]; then W_ST="\033[1;32m🟢畅通\033[0m"; W_INFO="IPv4: $W_IP"; else W_ST="\033[1;31m🔴断联\033[0m"; W_INFO="无法访问外网"; fi
printf "%-18s | %-21s | %s\n" "WARP 出口" "$W_ST" "$W_INFO"
echo -e "\033[1;36m========================================================\033[0m"
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

# [u] 自毁卸载
cat << 'EOF' > /usr/bin/u
#!/bin/bash
clear; echo -e "\033[1;31m⚠️ 正在卸载核心组件...\033[0m"
systemctl stop sing-box cloudflared warp-go 2>/dev/null
systemctl disable sing-box cloudflared 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/v /usr/bin/w /usr/bin/r /usr/bin/u /etc/systemd/system/sing-box.service
systemctl daemon-reload
echo -e "\033[1;33m👉 正在唤出 WARP 菜单，请选择卸载 WARP\033[0m"
[ -f "/root/CFwarp.sh" ] && bash /root/CFwarp.sh
rm -f /root/CFwarp.sh
sed -i '/prefer-family = IPv6/d' ~/.wgetrc 2>/dev/null
echo "🎉 物理超度完毕！机器已恢复纯净状态。"
EOF

chmod +x /usr/bin/v /usr/bin/c /usr/bin/w /usr/bin/r /usr/bin/u
echo -e "\n\033[1;32m🎉 极简双擎系统部署完毕！\033[0m"
echo -e "\033[1;37m👉 输入 \033[1;36mv\033[1;37m 提取节点并查看 Argo 隧道配置说明。\033[0m"
echo -e "\033[1;37m👉 输入 \033[1;36mc\033[1;37m 查看系统与网络监控大盘。\033[0m"
