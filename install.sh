#!/bin/bash
# ====================================================================
# 极简单轨 WARP 稳定版 (退回 3 协议架构 | 抛弃分流，回归稳定)
# 核心组件：WARP-GO + Sing-box(3通道) + st中控台
# ====================================================================
echo -e "\033[1;36m🚀 正在执行【极简单轨 WARP 稳定版】初始化...\033[0m"

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
HY2_ON=1
VLESS_ON=1
VMESS_ON=1
DOMAIN_VLESS=""
DOMAIN_VMESS=""
EOF

# ====================================================================
# 回归原始：没有任何 DNS 劫持，没有任何分流策略，纯粹的 Direct 出站
# ====================================================================
cat << 'EOF' > /usr/local/bin/sb_gen
#!/bin/bash
source /etc/s-box/status.env
INBOUNDS="[]"

[ "$HY2_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "hysteria2", "tag": "hy2-in", "listen": "::", "listen_port": 8443, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"}}]')
[ "$VLESS_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "vless", "tag": "vless-in", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "flow": ""}], "transport": {"type": "ws", "path": "/vless"}}]')
[ "$VMESS_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq '. + [{"type": "vmess", "tag": "vmess-in", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/vmess"}}]')

jq -n --argjson inbounds "$INBOUNDS" '{
    log: {level: "warn"},
    inbounds: $inbounds,
    outbounds: [
      {type: "direct", tag: "direct-out"}
    ],
    route: {
        auto_detect_interface: false
    }
}' > /etc/s-box/sing-box.json

systemctl restart sing-box >/dev/null 2>&1
EOF
chmod +x /usr/local/bin/sb_gen

cat > /etc/systemd/system/sing-box.service << 'EOF'
[Unit]
Description=Sing-box Dynamic Core
After=network.target
[Service]
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

echo -e "\n\033[1;35m🌌 第四阶段：构建极简中控台 (st)...\033[0m"
cat << 'EOF' > /usr/bin/st
#!/bin/bash
while true; do
    source /etc/s-box/status.env
    clear
    echo -e "\033[1;36m==================================================================\033[0m"
    echo -e "\033[1;37m             🛡️ 极简单轨 WARP 稳定版总控台 (稳如老狗)            \033[0m"
    echo -e "\033[1;36m==================================================================\033[0m"
    
    MEM=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }' 2>/dev/null || echo "未知")
    CPU=$(top -bn1 2>/dev/null | grep load | awk '{printf "%.2f", $(NF-2)}' || echo "未知")
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
    W_IP=$(curl -s4 -m 3 api.ipify.org 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
    [ -n "$W_IP" ] && W_ST="\033[1;32m🟢畅通\033[0m" || W_ST="\033[1;31m🔴断流\033[0m"
    
    echo -e " 💻 宿主: 运行 \033[1;37m${UPTIME}\033[0m | CPU: \033[1;37m$CPU\033[0m | 内存: \033[1;37m$MEM\033[0m"
    echo -e " 🌐 网络: WARP IPv4 ($W_ST) | 守护犬 (\033[1;32m🟢巡逻中\033[0m)"
    echo -e "------------------------------------------------------------------"
    
    [ "$HY2_ON" = "1" ] && S1="\033[1;32m🟢 运行中\033[0m" || S1="\033[1;31m💤 休眠\033[0m"
    [ "$VLESS_ON" = "1" ] && S2="\033[1;32m🟢 运行中\033[0m" || S2="\033[1;31m💤 休眠\033[0m"
    [ "$VMESS_ON" = "1" ] && S3="\033[1;32m🟢 运行中\033[0m" || S3="\033[1;31m💤 休眠\033[0m"

    echo -e " \033[1;33m>>> 🛡️ 核心出站协议 (默认全局经过 WARP IPv4) <<<\033[0m"
    echo -e "  [\033[1;36m1\033[0m] 切换 HY2    (公网UDP直连 8443)  | 状态: $S1"
    echo -e "  [\033[1;36m2\033[0m] 切换 VLESS  (Argo穿透绑定 10001) | 状态: $S2"
    echo -e "  [\033[1;36m3\033[0m] 切换 VMess  (Argo穿透绑定 10002) | 状态: $S3"
    echo -e "------------------------------------------------------------------"
    echo -e " \033[1;35m>>> ⚙️ 系统管理 <<<\033[0m"
    echo -e "  [\033[1;36m4\033[0m] ☁️ Argo 隧道部署 & 专属域名自动化绑定向导"
    echo -e "  [\033[1;36m5\033[0m] 🔗 提取所有直通节点 (自动填充域名)"
    echo -e "  [\033[1;36m6\033[0m] 📜 追踪 Sing-box 实时底层日志"
    echo -e "  [\033[1;36m7\033[0m] ⚠️ 执行物理自毁程序 (卸载清理)"
    echo -e "  [\033[1;36m0\033[0m] 🚪 退出面板"
    echo -e "\033[1;36m==================================================================\033[0m"
    
    read -p "👉 请输入指令 (0-7): " CMD
    case $CMD in
        1) [ "$HY2_ON" = "1" ] && N=0 || N=1; sed -i "s/^HY2_ON=.*/HY2_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        2) [ "$VLESS_ON" = "1" ] && N=0 || N=1; sed -i "s/^VLESS_ON=.*/VLESS_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        3) [ "$VMESS_ON" = "1" ] && N=0 || N=1; sed -i "s/^VMESS_ON=.*/VMESS_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 状态切换完毕！\033[0m"; sleep 1 ;;
        4)
            clear
            echo -e "\033[1;36m==================================================================\033[0m"
            echo -e "\033[1;32m                 ☁️ Argo 自动化部署与域名绑定向导                 \033[0m"
            echo -e "\033[1;36m==================================================================\033[0m"
            echo -e "\033[1;33m【第一步：部署 Argo 隧道 (已装可直接回车跳过)】\033[0m"
            read -p "🔑 请在此粘贴 CF 完整安装指令并回车: " RAW_INPUT
            ARGO_TOKEN=$(echo "$RAW_INPUT" | grep -oE 'eyJ[A-Za-z0-9_\-\.]+')
            
            if [ -n "$ARGO_TOKEN" ]; then
                echo -e "\033[1;35m⏳ 正在拉取并注册 Argo 系统服务...\033[0m"
                systemctl stop cloudflared 2>/dev/null; rm -f /usr/local/bin/cloudflared
                curl -sL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /usr/local/bin/cloudflared
                /usr/local/bin/cloudflared service install "$ARGO_TOKEN" >/dev/null 2>&1
                systemctl enable --now cloudflared >/dev/null 2>&1
                echo -e "\033[1;32m🎉 Argo 部署完毕！\033[0m\n"
            fi
            
            echo -e "\033[1;33m【第二步：录入专属域名】\033[0m"
            echo -e " \033[1;37m请确保在 CF 网页端将这些域名映射到了本地：\033[0m"
            echo -e "  * VLESS 映射到 \033[1;32mlocalhost:10001\033[0m"
            echo -e "  * VMess 映射到 \033[1;32mlocalhost:10002\033[0m"
            echo -e "\033[1;36m------------------------------------------------------------------\033[0m"
            read -p "👉 录入 [VLESS 10001] 映射的域名 (回车保持原样): " IN_D1
            [ -n "$IN_D1" ] && sed -i "s/^DOMAIN_VLESS=.*/DOMAIN_VLESS=$IN_D1/" /etc/s-box/status.env
            read -p "👉 录入 [VMess 10002] 映射的域名 (回车保持原样): " IN_D2
            [ -n "$IN_D2" ] && sed -i "s/^DOMAIN_VMESS=.*/DOMAIN_VMESS=$IN_D2/" /etc/s-box/status.env
            
            echo -e "\n\033[1;32m✅ 域名录入完毕！请按 5 提取节点！\033[0m"
            read -n 1 -s -r -p "按任意键返回主菜单..."
            ;;
        5)
            IP=$(curl -s6 -m 3 api64.ipify.org 2>/dev/null || ip -6 addr show | grep inet6 | awk '{print $2}' | cut -d/ -f1 | grep -v '^::1' | grep -v '^fe80' | head -n 1)
            [ -z "$IP" ] && IP="获取原生IPv6失败_请检查网卡"
            UUID="d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a"; PW="PsiphonUS_2026"
            
            D_V1=${DOMAIN_VLESS:-"未配置域名请替换"}
            D_M1=${DOMAIN_VMESS:-"未配置域名请替换"}
            
            echo ""
            if [ "$HY2_ON" = "1" ]; then echo -e "\033[1;35m[协议 1] HY2 (直连):\033[0m\n\033[40;32m hysteria2://$PW@[$IP]:8443/?sni=bing.com&insecure=1#WARP-HY2 \033[0m\n"; fi
            if [ "$VLESS_ON" = "1" ]; then 
                echo -e "\033[1;35m[协议 2] VLESS (Argo穿透):\033[0m\n\033[40;32m vless://$UUID@$D_V1:443?encryption=none&security=tls&sni=$D_V1&type=ws&host=$D_V1&path=%2Fvless#WARP-VLESS \033[0m\n"
            fi
            if [ "$VMESS_ON" = "1" ]; then echo -e "\033[1;35m[协议 3] VMess (Argo穿透):\033[0m\n\033[40;32m vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"WARP-VMess\",\"add\":\"$D_M1\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$D_M1\",\"path\":\"/vmess\",\"tls\":\"tls\"}" | base64 -w 0) \033[0m\n"; fi
            read -n 1 -s -r -p "按任意键返回菜单..."
            ;;
        6) echo -e "\033[1;36m📜 追踪底层日志 (Ctrl+C 退出)...\033[0m"; journalctl -u sing-box --no-pager --output cat -f -n 50 ;;
        7)
            echo -e "\033[1;31m⚠️ 正在执行物理卸载...\033[0m"
            systemctl stop sing-box cloudflared warp-go warp-dog 2>/dev/null
            systemctl disable sing-box cloudflared warp-dog 2>/dev/null
            rm -rf /etc/s-box /usr/local/bin/sb_gen /usr/local/bin/cloudflared /etc/systemd/system/cloudflared.service /etc/systemd/system/sing-box.service /etc/systemd/system/warp-dog.service /usr/bin/w_dog /usr/bin/tw /usr/bin/st
            systemctl daemon-reload
            [ -f "/root/CFwarp.sh" ] && bash /root/CFwarp.sh
            rm -f /root/CFwarp.sh
            echo -e "\033[1;32m🎉 彻底物理卸载完毕！系统已恢复。\033[0m"; exit 0
            ;;
        0) clear; exit 0 ;;
        *) echo -e "\033[1;31m❌ 无效指令！\033[0m"; sleep 1 ;;
    esac
done
EOF
chmod +x /usr/bin/st

echo -e "\n\033[1;32m🎉 极简单轨 WARP 稳定版部署完毕！\033[0m"
echo -e "\033[1;37m👉 请在终端输入 \033[1;33mst\033[1;37m 呼出天网大一统中控台！\033[0m"
