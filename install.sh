#!/bin/bash
# ====================================================================
# 极简单轨 WARP 稳定版 V3.1 (双源 IP 全自动引导·终极实验版)
# 核心：自动引导配置 (全局 WARP + 本地 SOCKS5) -> 鉴伪实验
# ====================================================================
echo -e "\033[1;36m🚀 正在执行【V3.1 双源 IP 全自动引导版】初始化...\033[0m"

if [ -f /etc/s-box/status.env ]; then cp /etc/s-box/status.env /tmp/status_backup.env; fi

systemctl stop sing-box cloudflared warp-dog 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/v /usr/bin/w /usr/bin/r /usr/bin/u /usr/bin/a /usr/bin/w_dog /usr/bin/tw /usr/bin/st /usr/local/bin/sb_gen
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget jq openssl cron nano coreutils >/dev/null 2>&1
mkdir -p /etc/s-box

echo "prefer-family = IPv6" > ~/.wgetrc
if [ ! -f /etc/gai.conf ]; then touch /etc/gai.conf; fi

# ====================================================================
# 智能双重环境侦测与自动引导 (核心修复)
# ====================================================================
echo -e "\n\033[1;32m🌐 正在校验 [第一重] 全局 WARP IPv4 状态...\033[0m"
if ! curl -s4 -m 5 api.ipify.org >/dev/null; then
    echo -e "\033[1;33m⚠️ 未检测到全局 IPv4，准备呼出勇哥脚本...\033[0m"
    echo -e "\033[1;31m👉 【步骤 1】请在接下来的菜单中，选择安装【WARP 全局模式】！\033[0m"
    echo -e "\033[1;31m👉 安装成功获取 IP 后，输入 0 退出菜单继续！\033[0m"
    sleep 5
    rm -f /root/CFwarp.sh
    curl -sL -o /root/CFwarp.sh https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh
    chmod +x /root/CFwarp.sh
    bash /root/CFwarp.sh
else
    echo -e "\033[1;32m✅ 全局 IPv4 已就绪！\033[0m"
fi

echo -e "\n\033[1;32m🌐 正在校验 [第二重] SOCKS5 (40000端口) 状态...\033[0m"
if ! curl -sx socks5h://127.0.0.1:40000 -m 5 api.ipify.org >/dev/null; then
    echo -e "\033[1;33m⚠️ 未检测到 SOCKS5 代理端口，准备再次呼出勇哥脚本...\033[0m"
    echo -e "\033[1;31m👉 【步骤 2】请在接下来的菜单中，选择【安装/管理 SOCKS5 代理】！\033[0m"
    echo -e "\033[1;31m👉 端口务必保持默认的 40000！安装完毕后输入 0 退出菜单！\033[0m"
    sleep 5
    rm -f /root/CFwarp.sh
    curl -sL -o /root/CFwarp.sh https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh
    chmod +x /root/CFwarp.sh
    bash /root/CFwarp.sh
else
    echo -e "\033[1;32m✅ 独立 SOCKS5 通道已就绪！\033[0m"
fi

echo -e "\n\033[1;33m📦 第三阶段：拉取 Sing-box 核心并构建双擎环境...\033[0m"
S_URL=$(curl -sL --connect-timeout 5 -A "Mozilla/5.0" "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -o 'https://[^"]*linux-amd64\.tar\.gz' | head -n 1)
[ -z "$S_URL" ] && S_URL="https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz"
curl -sL --connect-timeout 15 -o /tmp/sbox.tar.gz "$S_URL"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ 2>/dev/null
mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box 2>/dev/null
chmod +x /etc/s-box/sing-box

openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null

if [ -f /tmp/status_backup.env ]; then
    mv /tmp/status_backup.env /etc/s-box/status.env
else
    SYS_UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a")
    SYS_PW=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16 2>/dev/null || echo "TK_Proxy_2026")
    cat << EOF > /etc/s-box/status.env
HY2_ON=1
VLESS_ON=1
VMESS_ON=1
DOMAIN_VLESS=""
DOMAIN_VMESS=""
SYS_UUID="$SYS_UUID"
SYS_PW="$SYS_PW"
EOF
fi

cat << 'EOF' > /usr/local/bin/sb_gen
#!/bin/bash
source /etc/s-box/status.env
INBOUNDS="[]"

[ "$HY2_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq --arg pw "$SYS_PW" '. + [{"type": "hysteria2", "tag": "hy2-in", "listen": "::", "listen_port": 8443, "users": [{"password": $pw}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"}}]')
[ "$VLESS_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq --arg uuid "$SYS_UUID" '. + [{"type": "vless", "tag": "vless-in", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": $uuid, "flow": ""}], "transport": {"type": "ws", "path": "/vless"}}]')
[ "$VMESS_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq --arg uuid "$SYS_UUID" '. + [{"type": "vmess", "tag": "vmess-in", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": $uuid, "alterId": 0}], "transport": {"type": "ws", "path": "/vmess"}}]')

jq -n --argjson inbounds "$INBOUNDS" '{
    log: {level: "warn"},
    inbounds: $inbounds,
    outbounds: [
      {
        "type": "socks",
        "tag": "socks-out",
        "server": "127.0.0.1",
        "server_port": 40000
      },
      {
        "type": "direct",
        "tag": "direct-out"
      }
    ],
    route: {
        "rules": [
            {"inbound": ["hy2-in", "vless-in", "vmess-in"], "outbound": "socks-out"}
        ],
        "auto_detect_interface": false
    }
}' > /etc/s-box/sing-box.json
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

systemctl daemon-reload; /usr/local/bin/sb_gen; systemctl enable --now sing-box >/dev/null 2>&1

echo -e "\n\033[1;33m🐕 第四阶段：植入双路独立 IP 雷达探针...\033[0m"
cat << 'EOF' > /usr/bin/w_dog
#!/bin/bash
LOG_FILE="/etc/s-box/warp_dog.log"
touch "$LOG_FILE"
LAST_G_IP=$(cat /etc/s-box/last_g_ip.txt 2>/dev/null)
LAST_S_IP=$(cat /etc/s-box/last_s_ip.txt 2>/dev/null)

while true; do
    sleep 60
    if [ $(wc -l < "$LOG_FILE") -gt 1000 ]; then > "$LOG_FILE"; fi
    
    NEW_G_IP=$(curl -s4 -m 5 api.ipify.org 2>/dev/null)
    if [ -n "$NEW_G_IP" ] && [ "$NEW_G_IP" != "$LAST_G_IP" ]; then
        if [ -n "$LAST_G_IP" ]; then echo "$(date '+%m-%d %H:%M') | 🔄 全局漂移: $LAST_G_IP -> $NEW_G_IP" >> "/etc/s-box/drift.log"; fi
        echo "$NEW_G_IP" > /etc/s-box/last_g_ip.txt
        LAST_G_IP="$NEW_G_IP"
    fi

    NEW_S_IP=$(curl -sx socks5h://127.0.0.1:40000 -m 5 api.ipify.org 2>/dev/null)
    if [ -n "$NEW_S_IP" ] && [ "$NEW_S_IP" != "$LAST_S_IP" ]; then
        if [ -n "$LAST_S_IP" ]; then echo "$(date '+%m-%d %H:%M') | 🔄 节点漂移: $LAST_S_IP -> $NEW_S_IP" >> "/etc/s-box/drift.log"; fi
        echo "$NEW_S_IP" > /etc/s-box/last_s_ip.txt
        LAST_S_IP="$NEW_S_IP"
    fi
done
EOF
chmod +x /usr/bin/w_dog
cat > /etc/systemd/system/warp-dog.service << 'EOF'
[Unit]
Description=Dual IP Radar Watchdog
After=network.target
[Service]
ExecStart=/usr/bin/w_dog
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now warp-dog >/dev/null 2>&1

echo -e "\n\033[1;35m🌌 最终阶段：构建 V3.1 终极鉴伪中控台...\033[0m"
cat << 'EOF' > /usr/bin/st
#!/bin/bash
while true; do
    source /etc/s-box/status.env
    clear
    echo -e "\033[1;36m==================================================================\033[0m"
    echo -e "\033[1;37m        🛡️ 极简单轨稳定版总控台 (V3.1 异源双 IP 鉴伪版)      \033[0m"
    echo -e "\033[1;36m==================================================================\033[0m"
    
    MEM=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }' 2>/dev/null || echo "未知")
    CPU=$(top -bn1 2>/dev/null | grep load | awk '{printf "%.2f", $(NF-2)}' || echo "未知")
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
    
    V4_GLOBAL=$(curl -s4 -m 3 api.ipify.org 2>/dev/null)
    V4_SOCKS=$(curl -sx socks5h://127.0.0.1:40000 -m 3 api.ipify.org 2>/dev/null)
    
    [ -z "$V4_GLOBAL" ] && V4_G_DISP="\033[1;31m未获取到 (全局出站瘫痪)\033[0m" || V4_G_DISP="\033[1;37m$V4_GLOBAL\033[0m [\033[1;33m宿主全局承载\033[0m]"
    [ -z "$V4_SOCKS" ]  && V4_S_DISP="\033[1;31m40000端口不通 (SOCKS未开启)\033[0m" || V4_S_DISP="\033[1;32m$V4_SOCKS\033[0m [\033[1;36m节点独立出口\033[0m]"
    
    if [ -n "$V4_GLOBAL" ] && [ -n "$V4_SOCKS" ]; then
        if [ "$V4_GLOBAL" == "$V4_SOCKS" ]; then
            IP_STATUS="\033[1;31m⚠️ 警告: 两者 IP 相同，双开失去意义！\033[0m"
        else
            IP_STATUS="\033[1;32m🎉 恭喜: 获取到两枚独立 IP，双擎并联成功！\033[0m"
        fi
    else
        IP_STATUS="\033[1;90m⏳ 等待双路 IP 就绪...\033[0m"
    fi

    LAST_DRIFT=$(tail -n 1 /etc/s-box/drift.log 2>/dev/null | awk -F'|' '{print $2}')
    [ -z "$LAST_DRIFT" ] && LAST_DRIFT="\033[1;90m暂无漂移记录\033[0m" || LAST_DRIFT="\033[1;35m$LAST_DRIFT\033[0m"

    echo -e " 💻 宿主机: \033[1;37m${UPTIME}\033[0m | CPU: \033[1;37m$CPU\033[0m | 内存: \033[1;37m$MEM\033[0m"
    echo -e "------------------------------------------------------------------"
    echo -e " \033[1;35m>>> 🌐 异源双 IP 核显矩阵 (实时对照实验) <<<\033[0m"
    echo -e "  * 系统全局 IPv4: $V4_G_DISP"
    echo -e "  * 节点出站 IPv4: $V4_S_DISP"
    echo -e "  * 核心实验结论 : $IP_STATUS"
    echo -e "  * 动态漂移雷达 : $LAST_DRIFT"
    echo -e "------------------------------------------------------------------"
    
    [ "$HY2_ON" = "1" ] && S1="\033[1;32m🟢 运行中\033[0m" || S1="\033[1;31m💤 休眠\033[0m"
    [ "$VLESS_ON" = "1" ] && S2="\033[1;32m🟢 运行中\033[0m" || S2="\033[1;31m💤 休眠\033[0m"
    [ "$VMESS_ON" = "1" ] && S3="\033[1;32m🟢 运行中\033[0m" || S3="\033[1;31m💤 休眠\033[0m"

    echo -e " \033[1;33m>>> 🛡️ 核心入站引擎 (强行送入 SOCKS 独立 IP) <<<\033[0m"
    echo -e "  [\033[1;36m1\033[0m] 切换 HY2    (公网直连 8443)    | 状态: $S1"
    echo -e "  [\033[1;36m2\033[0m] 切换 VLESS  (Argo穿透 10001)   | 状态: $S2"
    echo -e "  [\033[1;36m3\033[0m] 切换 VMess  (Argo穿透 10002)   | 状态: $S3"
    echo -e "------------------------------------------------------------------"
    echo -e " \033[1;34m>>> ⚙️ 系统策略与工具 <<<\033[0m"
    echo -e "  [\033[1;36m4\033[0m] ☁️ Argo 隧道部署 & 专属域名绑定"
    echo -e "  [\033[1;36m5\033[0m] 🔗 提取所有节点链接 (自动填充高强度密钥)"
    echo -e "  [\033[1;36m6\033[0m] 📜 追踪 Sing-box 实时底层日志"
    echo -e "  [\033[1;36m7\033[0m] ⚠️ 执行物理自毁程序"
    echo -e "  [\033[1;36m0\033[0m] 🚪 退出面板"
    echo -e "\033[1;36m==================================================================\033[0m"
    
    read -p "👉 请输入指令 (0-7): " CMD
    case $CMD in
        1) [ "$HY2_ON" = "1" ] && N=0 || N=1; sed -i "s/^HY2_ON=.*/HY2_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 切换完毕！\033[0m"; sleep 1 ;;
        2) [ "$VLESS_ON" = "1" ] && N=0 || N=1; sed -i "s/^VLESS_ON=.*/VLESS_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 切换完毕！\033[0m"; sleep 1 ;;
        3) [ "$VMESS_ON" = "1" ] && N=0 || N=1; sed -i "s/^VMESS_ON=.*/VMESS_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; echo -e "\033[1;32m✅ 切换完毕！\033[0m"; sleep 1 ;;
        4)
            clear
            echo -e "\033[1;36m==================================================================\033[0m"
            read -p "🔑 粘贴 CF 完整安装指令并回车 (跳过直接回车): " RAW_INPUT
            ARGO_TOKEN=$(echo "$RAW_INPUT" | grep -oE 'eyJ[A-Za-z0-9_\-\.]+')
            if [ -n "$ARGO_TOKEN" ]; then
                echo -e "\033[1;35m⏳ 正在部署 Argo...\033[0m"
                systemctl stop cloudflared 2>/dev/null; rm -f /usr/local/bin/cloudflared
                curl -sL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /usr/local/bin/cloudflared
                /usr/local/bin/cloudflared service install "$ARGO_TOKEN" >/dev/null 2>&1
                systemctl enable --now cloudflared >/dev/null 2>&1
                echo -e "\033[1;32m🎉 Argo 部署完毕！\033[0m\n"
            fi
            read -p "👉 录入 [VLESS 10001] 域名 (回车保持): " IN_D1
            [ -n "$IN_D1" ] && sed -i "s/^DOMAIN_VLESS=.*/DOMAIN_VLESS=$IN_D1/" /etc/s-box/status.env
            read -p "👉 录入 [VMess 10002] 域名 (回车保持): " IN_D2
            [ -n "$IN_D2" ] && sed -i "s/^DOMAIN_VMESS=.*/DOMAIN_VMESS=$IN_D2/" /etc/s-box/status.env
            echo -e "\n\033[1;32m✅ 录入完毕！按 5 提取节点！\033[0m"; read -n 1 -s -r -p "按任意键返回..."
            ;;
        5)
            IP=$(curl -s6 -m 3 api64.ipify.org 2>/dev/null || ip -6 addr show | grep inet6 | awk '{print $2}' | cut -d/ -f1 | grep -v '^::1' | grep -v '^fe80' | head -n 1)
            [ -z "$IP" ] && IP="获取原生IPv6失败_请检查网卡"
            D_V1=${DOMAIN_VLESS:-"未配置域名请替换"}
            D_M1=${DOMAIN_VMESS:-"未配置域名请替换"}
            echo ""
            if [ "$HY2_ON" = "1" ]; then echo -e "\033[1;35m[协议 1] HY2 (代理出站):\033[0m\n\033[40;32m hysteria2://$SYS_PW@[$IP]:8443/?sni=bing.com&insecure=1#Socks-HY2 \033[0m\n"; fi
            if [ "$VLESS_ON" = "1" ]; then echo -e "\033[1;35m[协议 2] VLESS (Argo穿透):\033[0m\n\033[40;32m vless://$SYS_UUID@$D_V1:443?encryption=none&security=tls&sni=$D_V1&type=ws&host=$D_V1&path=%2Fvless#Socks-VLESS \033[0m\n"; fi
            if [ "$VMESS_ON" = "1" ]; then echo -e "\033[1;35m[协议 3] VMess (Argo穿透):\033[0m\n\033[40;32m vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"Socks-VMess\",\"add\":\"$D_M1\",\"port\":\"443\",\"id\":\"$SYS_UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$D_M1\",\"path\":\"/vmess\",\"tls\":\"tls\"}" | base64 -w 0) \033[0m\n"; fi
            read -n 1 -s -r -p "按任意键返回菜单..."
            ;;
        6) echo -e "\033[1;36m📜 追踪底层日志 (Ctrl+C 退出)...\033[0m"; journalctl -u sing-box --no-pager --output cat -f -n 50 ;;
        7)
            echo -e "\033[1;31m⚠️ 正在执行物理卸载...\033[0m"
            systemctl stop sing-box cloudflared warp-dog 2>/dev/null; systemctl disable sing-box cloudflared warp-dog 2>/dev/null
            rm -rf /etc/s-box /usr/local/bin/sb_gen /usr/local/bin/cloudflared /etc/systemd/system/cloudflared.service /etc/systemd/system/sing-box.service /etc/systemd/system/warp-dog.service /usr/bin/w_dog /usr/bin/tw /usr/bin/st; systemctl daemon-reload
            echo -e "\033[1;32m🎉 彻底卸载完毕！\033[0m"; exit 0 ;;
        0) clear; exit 0 ;;
        *) echo -e "\033[1;31m❌ 无效指令！\033[0m"; sleep 1 ;;
    esac
done
EOF
chmod +x /usr/bin/st

echo -e "\n\033[1;32m🎉 V3.1 自动引导版部署完毕！\033[0m"
echo -e "\033[1;37m👉 请在终端输入 \033[1;33mst\033[1;37m 呼出面板，看看你的双 IP 点亮了没有！\033[0m"
