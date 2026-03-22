#!/bin/bash
# ====================================================================
# 极简双轨三体矩阵系统 V1.5.5 (注入免死金牌 | 绝对防崩溃万能版)
# 核心组件：WARP-GO + Sing-box(双轨6通道) + TCP守护犬 + st中控台
# ====================================================================
echo -e "\033[1;36m🚀 正在执行【极简双轨三体矩阵系统 V1.5.5】初始化...\033[0m"

systemctl stop sing-box warp-go cloudflared warp-dog 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/v /usr/bin/w /usr/bin/r /usr/bin/u /usr/bin/a /usr/bin/w_dog /usr/bin/tw /usr/bin/st /usr/local/bin/sb_gen
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget jq openssl cron nano coreutils >/dev/null 2>&1
mkdir -p /etc/s-box

echo "prefer-family = IPv6" > ~/.wgetrc
sed -i '/precedence ::ffff:0:0\/96  10/d' /etc/gai.conf 2>/dev/null

echo -e "\n\033[1;32m🌐 正在校验 WARP IPv4 连通性...\033[0m"
if ! curl -s4 -m 5 api.ipify.org >/dev/null; then
    rm -f /root/CFwarp.sh
    curl -sL -o /root/CFwarp.sh https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh
    chmod +x /root/CFwarp.sh
    echo -e "\033[1;33m⚠️ 未检测到 WARP，请手动安装 (建议双栈/单栈IPv4)，成功获取IP后输 0 退出！\033[0m"
    sleep 3; bash /root/CFwarp.sh
fi

echo -e "\n\033[1;33m📦 第二阶段：拉取 Sing-box 核心并植入状态机...\033[0m"
S_URL=$(curl -sL --connect-timeout 5 -A "Mozilla/5.0" "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -o 'https://[^"]*linux-amd64\.tar\.gz' | head -n 1)
[ -z "$S_URL" ] && S_URL="https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz"
curl -sL --connect-timeout 15 -o /tmp/sbox.tar.gz "$S_URL"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ 2>/dev/null
mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box 2>/dev/null
chmod +x /etc/s-box/sing-box

openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null

cat << 'EOF' > /etc/s-box/status.env
HY2_V6=1
VLESS_V6=1
VMESS_V6=1
HY2_V4=1
VLESS_V4=1
VMESS_V4=1
DOMAIN_VLESS_V6=""
DOMAIN_VMESS_V6=""
DOMAIN_VLESS_V4=""
DOMAIN_VMESS_V4=""
EOF

# ====================================================================
# 回归最稳定架构：依赖双轨策略，丢弃激进语法
# ====================================================================
cat << 'EOF' > /usr/local/bin/sb_gen
#!/bin/bash
source /etc/s-box/status.env
INBOUNDS="[]"
V6_TAGS="[]"
V4_TAGS="[]"

[ "$HY2_V6" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "hysteria2", "tag": "hy2-v6-in", "listen": "::", "listen_port": 8443, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"}, "sniff": true, "sniff_override_destination": true}]') && V6_TAGS=$(echo "$V6_TAGS" | jq '. + ["hy2-v6-in"]')
[ "$VLESS_V6" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "vless", "tag": "vless-v6-in", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "flow": ""}], "transport": {"type": "ws", "path": "/vless-v6"}, "sniff": true, "sniff_override_destination": true}]') && V6_TAGS=$(echo "$V6_TAGS" | jq '. + ["vless-v6-in"]')
[ "$VMESS_V6" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "vmess", "tag": "vmess-v6-in", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/vmess-v6"}, "sniff": true, "sniff_override_destination": true}]') && V6_TAGS=$(echo "$V6_TAGS" | jq '. + ["vmess-v6-in"]')

[ "$HY2_V4" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "hysteria2", "tag": "hy2-v4-in", "listen": "::", "listen_port": 8444, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"}, "sniff": true, "sniff_override_destination": true}]') && V4_TAGS=$(echo "$V4_TAGS" | jq '. + ["hy2-v4-in"]')
[ "$VLESS_V4" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "vless", "tag": "vless-v4-in", "listen": "127.0.0.1", "listen_port": 10003, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "flow": ""}], "transport": {"type": "ws", "path": "/vless-v4"}, "sniff": true, "sniff_override_destination": true}]') && V4_TAGS=$(echo "$V4_TAGS" | jq '. + ["vless-v4-in"]')
[ "$VMESS_V4" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "vmess", "tag": "vmess-v4-in", "listen": "127.0.0.1", "listen_port": 10004, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/vmess-v4"}, "sniff": true, "sniff_override_destination": true}]') && V4_TAGS=$(echo "$V4_TAGS" | jq '. + ["vmess-v4-in"]')

RULES="[]"
[ "$(echo "$V6_TAGS" | jq 'length')" -gt 0 ] && RULES=$(echo "$RULES" | jq --argjson tags "$V6_TAGS" '. + [{"inbound": $tags, "outbound": "direct-v6"}]')
[ "$(echo "$V4_TAGS" | jq 'length')" -gt 0 ] && RULES=$(echo "$RULES" | jq --argjson tags "$V4_TAGS" '. + [{"inbound": $tags, "outbound": "direct-v4"}]')

jq -n --argjson inbounds "$INBOUNDS" --argjson rules "$RULES" '{
    log: {level: "error"},
    inbounds: $inbounds,
    outbounds: [
      {type: "direct", tag: "direct-v6", domain_strategy: "ipv6_only"},
      {type: "direct", tag: "direct-v4", domain_strategy: "ipv4_only"}
    ],
    route: {
        rules: $rules,
        auto_detect_interface: false
    }
}' > /etc/s-box/sing-box.json

systemctl restart sing-box >/dev/null 2>&1
EOF
chmod +x /usr/local/bin/sb_gen

# ====================================================================
# 终极护航：两道官方特赦金牌，强行接管内核配置
# ====================================================================
cat > /etc/systemd/system/sing-box.service << 'EOF'
[Unit]
Description=Sing-box Dynamic Core
After=network.target
[Service]
Environment="ENABLE_DEPRECATED_LEGACY_DOMAIN_STRATEGY_OPTIONS=true"
Environment="ENABLE_DEPRECATED_LEGACY_DNS_SERVERS=true"
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
LimitNOFILE=512000
[Install]
WantedBy=multi-user.target
EOF

/usr/local/bin/sb_gen
systemctl daemon-reload && systemctl enable --now sing-box >/dev/null 2>&1

echo -e "\n\033[1;33m🐕 第三阶段：植入 WARP TCP 无感守护犬...\033[0m"
cat << 'EOF' > /usr/bin/w_dog
#!/bin/bash
LOG_FILE="/etc/s-box/warp_dog.log"
touch "$LOG_FILE"
while true; do
    sleep 60
    if [ $(wc -l < "$LOG_FILE") -gt 1000 ]; then > "$LOG_FILE"; fi
    if ! curl -s4 -m 3 "http://1.1.1.1/cdn-cgi/trace" >/dev/null 2>&1; then
        sleep 5
        if ! curl -s4 -m 3 "http://1.0.0.1/cdn-cgi/trace" >/dev/null 2>&1; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') | 🚨 WARP 死锁！执行心肺复苏..." >> "$LOG_FILE"
            systemctl restart warp-go 2>/dev/null
            sleep 15
        fi
    fi
done
EOF
chmod +x /usr/bin/w_dog
cat > /etc/systemd/system/warp-dog.service << 'EOF'
[Unit]
Description=WARP TCP Watchdog
After=network.target
[Service]
ExecStart=/usr/bin/w_dog
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now warp-dog >/dev/null 2>&1

echo -e "\n\033[1;35m🌌 第四阶段：构建天网大一统中控台 (st)...\033[0m"
cat << 'EOF' > /usr/bin/st
#!/bin/bash
while true; do
    source /etc/s-box/status.env
    clear
    echo -e "\033[1;36m==================================================================\033[0m"
    echo -e "\033[1;37m           🛡️ 极简双轨三体矩阵总控台 (V1.5.5 万能兼容版)          \033[0m"
    echo -e "\033[1;36m==================================================================\033[0m"
    
    MEM=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }' 2>/dev/null || echo "未知")
    CPU=$(top -bn1 2>/dev/null | grep load | awk '{printf "%.2f", $(NF-2)}' || echo "未知")
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
    W_IP=$(curl -s4 -m 3 api.ipify.org 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
    [ -n "$W_IP" ] && W_ST="\033[1;32m🟢畅通\033[0m" || W_ST="\033[1;31m🔴断流\033[0m"
    RESCUE_COUNT=$(grep "$(date '+%Y-%m-%d')" /etc/s-box/warp_dog.log 2>/dev/null | grep "心肺复苏" | wc -l)
    
    echo -e " 💻 宿主: 运行 \033[1;37m${UPTIME}\033[0m | CPU: \033[1;37m$CPU\033[0m | 内存: \033[1;37m$MEM\033[0m"
    echo -e " 🌐 网络: WARP IPv4 ($W_ST) | TCP守护犬 (\033[1;32m🟢巡逻中\033[0m | 今日抢救: \033[1;33m${RESCUE_COUNT:-0}\033[0m 次)"
    echo -e "------------------------------------------------------------------"
    
    [ "$HY2_V6" = "1" ] && S1="\033[1;32m🟢 运行中\033[0m" || S1="\033[1;31m💤 物理休眠\033[0m"
    [ "$VLESS_V6" = "1" ] && S2="\033[1;32m🟢 运行中\033[0m" || S2="\033[1;31m💤 物理休眠\033[0m"
    [ "$VMESS_V6" = "1" ] && S3="\033[1;32m🟢 运行中\033[0m" || S3="\033[1;31m💤 物理休眠\033[0m"
    
    [ "$HY2_V4" = "1" ] && S4="\033[1;32m🟢 运行中\033[0m" || S4="\033[1;31m💤 物理休眠\033[0m"
    [ "$VLESS_V4" = "1" ] && S5="\033[1;32m🟢 运行中\033[0m" || S5="\033[1;31m💤 物理休眠\033[0m"
    [ "$VMESS_V4" = "1" ] && S6="\033[1;32m🟢 运行中\033[0m" || S6="\033[1;31m💤 物理休眠\033[0m"

    echo -e " \033[1;35m>>> 🚄 A 轨：原生 IPv6 极速直通总线 (仅限V6网站，极限速度) <<<\033[0m"
    echo -e "  [\033[1;36m1\033[0m] 切换 HY2    (原生UDP直连 8443)  | 状态: $S1"
    echo -e "  [\033[1;36m2\033[0m] 切换 VLESS  (Argo穿透 10001)    | 状态: $S2"
    echo -e "  [\033[1;36m3\033[0m] 切换 VMess  (Argo穿透 10002)    | 状态: $S3"
    echo ""
    echo -e " \033[1;34m>>> 🛸 B 轨：WARP IPv4 兼容穿透总线 (通杀全网，优质解锁) <<<\033[0m"
    echo -e "  [\033[1;36m4\033[0m] 切换 HY2    (WARP底层中转 8444) | 状态: $S4"
    echo -e "  [\033[1;36m5\033[0m] 切换 VLESS  (Argo穿透 10003)    | 状态: $S5"
    echo -e "  [\033[1;36m6\033[0m] 切换 VMess  (Argo穿透 10004)    | 状态: $S6"
    echo -e "------------------------------------------------------------------"
    echo -e " \033[1;33m>>> ⚙️ 系统全局调度 <<<\033[0m"
    echo -e "  [\033[1;36m7\033[0m] ☁️ Argo 隧道部署 & 专属域名自动化绑定向导"
    echo -e "  [\033[1;36m8\033[0m] 🔗 提取所有免修改直通节点 (自动填充系统级IP与域名)"
    echo -e "  [\033[1;36m9\033[0m] 📜 追踪 Sing-box 实时底层日志"
    echo -e "  [\033[1;36m10\033[0m] ⚠️ 执行物理自毁程序 (删库跑路)"
    echo -e "  [\033[1;36m0\033[0m] 🚪 退出面板"
    echo -e "\033[1;36m==================================================================\033[0m"
    
    read -p "👉 请输入指令 (0-10): " CMD
    case $CMD in
        1) [ "$HY2_V6" = "1" ] && N=0 || N=1; sed -i "s/^HY2_V6=.*/HY2_V6=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        2) [ "$VLESS_V6" = "1" ] && N=0 || N=1; sed -i "s/^VLESS_V6=.*/VLESS_V6=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        3) [ "$VMESS_V6" = "1" ] && N=0 || N=1; sed -i "s/^VMESS_V6=.*/VMESS_V6=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        4) [ "$HY2_V4" = "1" ] && N=0 || N=1; sed -i "s/^HY2_V4=.*/HY2_V4=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        5) [ "$VLESS_V4" = "1" ] && N=0 || N=1; sed -i "s/^VLESS_V4=.*/VLESS_V4=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        6) [ "$VMESS_V4" = "1" ] && N=0 || N=1; sed -i "s/^VMESS_V4=.*/VMESS_V4=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        7)
            clear
            echo -e "\033[1;36m==================================================================\033[0m"
            echo -e "\033[1;32m           ☁️ Argo 自动化部署与【免修改】域名绑定向导           \033[0m"
            echo -e "\033[1;36m==================================================================\033[0m"
            echo -e "\033[1;33m【第一步：部署或更新 Argo 隧道】\033[0m"
            echo -e " 1. 登录 Cloudflare Zero Trust 后台 -> Networks -> Tunnels"
            echo -e " 2. 点击 Create a tunnel (选 Cloudflared) 并复制安装指令"
            echo -e "\033[1;90m (提示：如果你已经安装过 Argo，可直接按回车跳过部署，仅绑定域名)\033[0m"
            read -p "🔑 请在此粘贴 CF 完整安装指令并回车: " RAW_INPUT
            ARGO_TOKEN=$(echo "$RAW_INPUT" | grep -oE 'eyJ[A-Za-z0-9_\-\.]+')
            
            if [ -n "$ARGO_TOKEN" ]; then
                echo -e "\033[1;35m⏳ 正在静默拉取并注册 Argo 系统服务...\033[0m"
                systemctl stop cloudflared 2>/dev/null; rm -f /usr/local/bin/cloudflared
                curl -sL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /usr/local/bin/cloudflared
                /usr/local/bin/cloudflared service install "$ARGO_TOKEN" >/dev/null 2>&1
                systemctl enable --now cloudflared >/dev/null 2>&1
                echo -e "\033[1;32m🎉 Argo 守护进程部署完毕！\033[0m\n"
            fi
            
            echo -e "\033[1;33m【第二步：录入专属域名 (实现节点复制即用)】\033[0m"
            echo -e " \033[1;37m请确保你已经在 CF 网页端将这些域名按如下规则映射到了本地端口：\033[0m"
            echo -e " \033[1;90m(注意：映射 URL 必须填写 \033[1;32m127.0.0.1\033[1;90m 而非 localhost)\033[0m"
            echo -e "  * 映射到 \033[1;32m127.0.0.1:10001\033[0m (对应 A轨 VLESS 原生极速)"
            echo -e "  * 映射到 \033[1;32m127.0.0.1:10002\033[0m (对应 A轨 VMess 原生极速)"
            echo -e "  * 映射到 \033[1;32m127.0.0.1:10003\033[0m (对应 B轨 VLESS WARP兼容)"
            echo -e "  * 映射到 \033[1;32m127.0.0.1:10004\033[0m (对应 B轨 VMess WARP兼容)"
            echo -e "\033[1;36m------------------------------------------------------------------\033[0m"
            
            read -p "👉 录入 [A轨 VLESS 10001] 映射的域名 (直接回车保持原样): " IN_D1
            [ -n "$IN_D1" ] && sed -i "s/^DOMAIN_VLESS_V6=.*/DOMAIN_VLESS_V6=$IN_D1/" /etc/s-box/status.env
            
            read -p "👉 录入 [A轨 VMess 10002] 映射的域名 (直接回车保持原样): " IN_D2
            [ -n "$IN_D2" ] && sed -i "s/^DOMAIN_VMESS_V6=.*/DOMAIN_VMESS_V6=$IN_D2/" /etc/s-box/status.env
            
            read -p "👉 录入 [B轨 VLESS 10003] 映射的域名 (直接回车保持原样): " IN_D3
            [ -n "$IN_D3" ] && sed -i "s/^DOMAIN_VLESS_V4=.*/DOMAIN_VLESS_V4=$IN_D3/" /etc/s-box/status.env
            
            read -p "👉 录入 [B轨 VMess 10004] 映射的域名 (直接回车保持原样): " IN_D4
            [ -n "$IN_D4" ] && sed -i "s/^DOMAIN_VMESS_V4=.*/DOMAIN_VMESS_V4=$IN_D4/" /etc/s-box/status.env
            
            echo -e "\n\033[1;32m✅ 域名录入完毕！现在请按 8 提取免修改节点！\033[0m"
            echo ""
            read -n 1 -s -r -p "按任意键返回主菜单..."
            ;;
        8)
            IP=$(curl -s6 -m 3 api64.ipify.org 2>/dev/null || ip -6 addr show | grep inet6 | awk '{print $2}' | cut -d/ -f1 | grep -v '^::1' | grep -v '^fe80' | head -n 1)
            [ -z "$IP" ] && IP="获取原生IPv6失败_请检查网卡"
            UUID="d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a"; PW="PsiphonUS_2026"
            
            D_V1=${DOMAIN_VLESS_V6:-"未配置域名请在此替换"}
            D_M1=${DOMAIN_VMESS_V6:-"未配置域名请在此替换"}
            D_V2=${DOMAIN_VLESS_V4:-"未配置域名请在此替换"}
            D_M2=${DOMAIN_VMESS_V4:-"未配置域名请在此替换"}
            
            echo ""
            if [ "$HY2_V6" = "1" ]; then echo -e "\033[1;35m[A轨] HY2 (原生 V6):\033[0m\n\033[40;32m hysteria2://$PW@[$IP]:8443/?sni=bing.com&insecure=1#A轨-原生-HY2 \033[0m\n"; fi
            if [ "$VLESS_V6" = "1" ]; then 
                echo -e "\033[1;35m[A轨] VLESS (原生 V6 / Argo穿透):\033[0m\n\033[40;32m vless://$UUID@$D_V1:443?encryption=none&security=tls&sni=$D_V1&type=ws&host=$D_V1&path=%2Fvless-v6#A轨-VLESS-直连 \033[0m"
                echo -e "\033[1;90m(提示：当前默认直连您的专属域名保证连通率。若需极致提速，可在客户端把【地址/Address】改为优选IP)\033[0m\n"
            fi
            if [ "$VMESS_V6" = "1" ]; then echo -e "\033[1;35m[A轨] VMess (原生 V6 / Argo穿透):\033[0m\n\033[40;32m vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"A轨-VMess\",\"add\":\"$D_M1\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$D_M1\",\"path\":\"/vmess-v6\",\"tls\":\"tls\"}" | base64 -w 0) \033[0m\n"; fi
            
            if [ "$HY2_V4" = "1" ]; then echo -e "\033[1;34m[B轨] HY2 (WARP V4兼容):\033[0m\n\033[40;32m hysteria2://$PW@[$IP]:8444/?sni=bing.com&insecure=1#B轨-WARP-HY2 \033[0m\n"; fi
            if [ "$VLESS_V4" = "1" ]; then 
                echo -e "\033[1;34m[B轨] VLESS (WARP V4 / Argo穿透):\033[0m\n\033[40;32m vless://$UUID@$D_V2:443?encryption=none&security=tls&sni=$D_V2&type=ws&host=$D_V2&path=%2Fvless-v4#B轨-VLESS-直连 \033[0m"
                echo -e "\033[1;90m(提示：当前默认直连您的专属域名保证连通率。若需极致提速，可在客户端把【地址/Address】改为优选IP)\033[0m\n"
            fi
            if [ "$VMESS_V4" = "1" ]; then echo -e "\033[1;34m[B轨] VMess (WARP V4 / Argo穿透):\033[0m\n\033[40;32m vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"B轨-VMess\",\"add\":\"$D_M2\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$D_M2\",\"path\":\"/vmess-v4\",\"tls\":\"tls\"}" | base64 -w 0) \033[0m\n"; fi
            read -n 1 -s -r -p "按任意键返回菜单..."
            ;;
        9) echo -e "\033[1;36m📜 追踪底层日志 (Ctrl+C 退出)...\033[0m"; journalctl -u sing-box --no-pager --output cat -f -n 50 ;;
        10)
            echo -e "\033[1;31m⚠️ 正在执行物理自毁...\033[0m"
            systemctl stop sing-box cloudflared warp-go warp-dog 2>/dev/null
            systemctl disable sing-box cloudflared warp-dog 2>/dev/null
            rm -rf /etc/s-box /usr/local/bin/sb_gen /usr/local/bin/cloudflared /etc/systemd/system/cloudflared.service /etc/systemd/system/sing-box.service /etc/systemd/system/warp-dog.service /usr/bin/w_dog /usr/bin/tw /usr/bin/st
            systemctl daemon-reload
            [ -f "/root/CFwarp.sh" ] && bash /root/CFwarp.sh
            rm -f /root/CFwarp.sh
            echo -e "\033[1;32m🎉 彻底物理超度完毕！系统已恢复出厂纯净。\033[0m"; exit 0
            ;;
        0) clear; exit 0 ;;
        *) echo -e "\033[1;31m❌ 无效指令！\033[0m"; sleep 1 ;;
    esac
done
EOF
chmod +x /usr/bin/st

echo -e "\n\033[1;32m🎉 极简双轨三体矩阵 V1.5.5 (万能兼容版) 部署完毕！\033[0m"
echo -e "\033[1;37m👉 请在终端输入 \033[1;33mst\033[1;37m 呼出天网大一统中控台！\033[0m"
