#!/bin/bash
# ====================================================================
# 极简单轨稳定版 V3.0 (终极臻纯·典藏版)
# 核心架构：双栈独立时序监控 + 智能嗅探 + Sing-box(桥接双语法) + st中控台
# 更新说明：完美修复优先路由脱轨问题，重构守护进程解耦，支持旧版配置自愈平滑升级
# ====================================================================
echo -e "\033[1;36m🚀 正在执行【极简单轨稳定版 V3.0 典藏版】部署...\033[0m"

# ================= 1. 环境清理与状态自愈 =================
if [ -f /etc/s-box/status.env ]; then
    cp /etc/s-box/status.env /tmp/status_backup.env
    echo -e "\033[1;32m✅ 检测到历史配置，已自动备份，准备平滑自愈升级...\033[0m"
fi

systemctl stop sing-box cloudflared warp-dog 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/v /usr/bin/w /usr/bin/w_dog /usr/bin/st /usr/local/bin/sb_gen
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget jq openssl cron nano coreutils iproute2 >/dev/null 2>&1
mkdir -p /etc/s-box
touch /etc/s-box/drift.log /etc/s-box/warp_dog.log
if [ ! -f /etc/gai.conf ]; then touch /etc/gai.conf; fi

# ================= 2. 智能嗅探与全局侦测 =================
echo -e "\n\033[1;34m🔍 正在智能嗅探系统 WARP 核心与网络环境...\033[0m"
WARP_SRV="none"
systemctl is-active --quiet wg-quick@wgcf && WARP_SRV="wg-quick@wgcf"
systemctl is-active --quiet warp-go && WARP_SRV="warp-go"
systemctl is-active --quiet warp-svc && WARP_SRV="warp-svc"

if [ "$WARP_SRV" != "none" ]; then
    echo -e "\033[1;32m✅ 智能嗅探成功：已接管底层 WARP 核心 [$WARP_SRV]\033[0m"
else
    echo -e "\033[1;33m⚠️ 警告：未检测到已知 WARP 服务 (wgcf/warp-go/warp-svc)，死锁唤醒将挂起。\033[0m"
fi

W_V4_ON=$(curl -s4 -m 3 "https://1.1.1.1/cdn-cgi/trace" 2>/dev/null | grep -q "warp=" && echo "1" || echo "0")
W_V6_ON=$(curl -s6 -m 3 "https://[2606:4700:4700::1111]/cdn-cgi/trace" 2>/dev/null | grep -q "warp=" && echo "1" || echo "0")
echo -e "📡 双栈侦测结果: IPv4 接管 [\033[1;36m$W_V4_ON\033[0m] | IPv6 接管 [\033[1;36m$W_V6_ON\033[0m]"
sleep 1

# ================= 3. 策略优先级向导 =================
echo -e "\n\033[1;36m==================================================================\033[0m"
echo -e "\033[1;33m🚦 初始化：请配置本机的默认【出站优先级】\033[0m"
echo -e "\033[1;36m==================================================================\033[0m"
echo -e " [\033[1;32m1\033[0m] IPv4 优先出战 (推荐！防双栈死锁，兼容性最强)"
echo -e " [\033[1;32m2\033[0m] IPv6 优先出战 (适合纯 IPv6 机器或特定解锁需求)"
read -p "👉 请选择 (1/2，直接回车默认选 1): " PRIO_CHOICE

sed -i '/^precedence ::ffff:0:0\/96/d' /etc/gai.conf 2>/dev/null
if [ "$PRIO_CHOICE" = "2" ]; then
    echo "precedence ::ffff:0:0/96  10" >> /etc/gai.conf
    echo -e "\033[1;32m✅ 已写入底层系统路由：IPv6 优先出战\033[0m"
else
    echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
    echo -e "\033[1;32m✅ 已写入底层系统路由：IPv4 优先出战\033[0m"
fi
sleep 1

# ================= 4. 核心拉取与变量重组 =================
echo -e "\n\033[1;34m📦 正在部署 Sing-box 核心并生成动态伪装...\033[0m"
S_URL=$(curl -sL --connect-timeout 3 -A "Mozilla/5.0" "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -o 'https://[^"]*linux-amd64\.tar\.gz' | head -n 1)
[ -z "$S_URL" ] && S_URL="https://github.com/SagerNet/sing-box/releases/download/v1.11.4/sing-box-1.11.4-linux-amd64.tar.gz"
curl -sL --connect-timeout 15 -o /tmp/sbox.tar.gz "$S_URL"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ 2>/dev/null
mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box 2>/dev/null
chmod +x /etc/s-box/sing-box

# 状态恢复与变量补全 (防断层升级逻辑)
if [ -f /tmp/status_backup.env ]; then
    mv /tmp/status_backup.env /etc/s-box/status.env
    source /etc/s-box/status.env
    if ! grep -q "HY2_SNI" /etc/s-box/status.env; then
        SNI_POOL=("apple.com" "microsoft.com" "amazon.com" "cloudflare.com" "github.com")
        echo "HY2_SNI=\"${SNI_POOL[$RANDOM % ${#SNI_POOL[@]}]}\"" >> /etc/s-box/status.env
    fi
    sed -i '/^WARP_SRV=/d' /etc/s-box/status.env; echo "WARP_SRV=\"$WARP_SRV\"" >> /etc/s-box/status.env
    sed -i '/^W_V4_ON=/d' /etc/s-box/status.env; echo "W_V4_ON=\"$W_V4_ON\"" >> /etc/s-box/status.env
    sed -i '/^W_V6_ON=/d' /etc/s-box/status.env; echo "W_V6_ON=\"$W_V6_ON\"" >> /etc/s-box/status.env
else
    SYS_UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a")
    SYS_PW=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16 2>/dev/null || echo "TK_Proxy_2026")
    SNI_POOL=("apple.com" "microsoft.com" "amazon.com" "cloudflare.com" "github.com")
    cat << EOF > /etc/s-box/status.env
HY2_ON=1
VLESS_ON=1
VMESS_ON=1
DOMAIN_VLESS=""
DOMAIN_VMESS=""
SYS_UUID="$SYS_UUID"
SYS_PW="$SYS_PW"
HY2_SNI="${SNI_POOL[$RANDOM % ${#SNI_POOL[@]}]}"
WARP_SRV="$WARP_SRV"
W_V4_ON="$W_V4_ON"
W_V6_ON="$W_V6_ON"
EOF
fi

source /etc/s-box/status.env
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=${HY2_SNI}" 2>/dev/null

# ================= 5. Sing-box 桥接路由生成器 =================
cat << 'EOF' > /usr/local/bin/sb_gen
#!/bin/bash
source /etc/s-box/status.env
INBOUNDS="[]"

[ "$HY2_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq --arg pw "$SYS_PW" --arg sni "$HY2_SNI" '. + [{"type": "hysteria2", "tag": "hy2-in", "listen": "::", "listen_port": 8443, "users": [{"password": $pw}], "tls": {"enabled": true, "server_name": $sni, "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"}}]')
[ "$VLESS_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq --arg uuid "$SYS_UUID" '. + [{"type": "vless", "tag": "vless-in", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": $uuid, "flow": ""}], "transport": {"type": "ws", "path": "/vless"}}]')
[ "$VMESS_ON" = "1" ] && INBOUNDS=$(echo "$INBOUNDS" | jq --arg uuid "$SYS_UUID" '. + [{"type": "vmess", "tag": "vmess-in", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": $uuid, "alterId": 0}], "transport": {"type": "ws", "path": "/vmess"}}]')

if grep -q "^precedence ::ffff:0:0/96.*100" /etc/gai.conf 2>/dev/null; then
    STRATEGY="prefer_ipv4"
else
    STRATEGY="prefer_ipv6"
fi

jq -n --argjson inbounds "$INBOUNDS" --arg strategy "$STRATEGY" '{
    log: {level: "warn"},
    inbounds: $inbounds,
    outbounds: [
      { type: "direct", tag: "direct-out", domain_strategy: $strategy }
    ],
    route: {
        auto_detect_interface: false
    }
}' > /etc/s-box/sing-box.json
EOF
chmod +x /usr/local/bin/sb_gen

cat > /etc/systemd/system/sing-box.service << 'EOF'
[Unit]
Description=Sing-box Dynamic Core V3
After=network.target
[Service]
Environment="ENABLE_DEPRECATED_LEGACY_DOMAIN_STRATEGY_OPTIONS=true"
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
/usr/local/bin/sb_gen
systemctl enable --now sing-box >/dev/null 2>&1

# ================= 6. 解耦版双栈时序雷达 =================
echo -e "\n\033[1;34m🐕 正在植入完全解耦版双栈时序雷达...\033[0m"
cat << 'EOF' > /usr/bin/w_dog
#!/bin/bash
LOG_FILE="/etc/s-box/drift.log"
SYS_LOG="/etc/s-box/warp_dog.log"
V4_FILE="/etc/s-box/last_v4.txt"
V6_FILE="/etc/s-box/last_v6.txt"

check_and_log() {
    local TYPE=$1; local TRACE_URL=$2; local FILE_PATH=$3
    local CURRENT_TIME=$(date +%s); local HUMAN_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    local TRACE_OUT=$(curl -s -m 5 "$TRACE_URL")
    
    if ! echo "$TRACE_OUT" | grep -q "warp="; then return 1; fi
    local NEW_IP=$(echo "$TRACE_OUT" | grep "ip=" | cut -d= -f2)
    if [ -z "$NEW_IP" ]; then return 1; fi

    if [ ! -f "$FILE_PATH" ]; then echo "$NEW_IP|$CURRENT_TIME" > "$FILE_PATH"; return 0; fi

    local LAST_DATA=$(cat "$FILE_PATH")
    local LAST_IP=$(echo "$LAST_DATA" | cut -d\| -f1)
    local LAST_TIME=$(echo "$LAST_DATA" | cut -d\| -f2)

    if [ "$NEW_IP" != "$LAST_IP" ]; then
        local DIFF=$(($CURRENT_TIME - $LAST_TIME))
        local D=$(($DIFF/86400)); local H=$((($DIFF%86400)/3600)); local M=$((($DIFF%3600)/60))
        local DURATION="${D}天${H}小时${M}分"
        echo "[$TYPE 记录] $HUMAN_TIME: $LAST_IP ➡️ $NEW_IP (稳定维持: $DURATION)" >> "$LOG_FILE"
        echo "$NEW_IP|$CURRENT_TIME" > "$FILE_PATH"
    fi
    return 0
}

while true; do
    sleep 60
    source /etc/s-box/status.env
    if [ $(wc -l < "$SYS_LOG" 2>/dev/null || echo 0) -gt 500 ]; then > "$SYS_LOG"; fi

    if [ "$W_V4_ON" = "1" ]; then
        if ! check_and_log "V4" "https://1.1.1.1/cdn-cgi/trace" "$V4_FILE"; then
            if ! curl -s4 -m 5 "http://1.0.0.1/cdn-cgi/trace" >/dev/null 2>&1; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') | 🚨 IPv4 探测死锁，尝试唤醒 ($WARP_SRV)..." >> "$SYS_LOG"
                [ "$WARP_SRV" != "none" ] && systemctl restart "$WARP_SRV"
                sleep 15
            fi
        fi
    fi

    if [ "$W_V6_ON" = "1" ]; then
        if ! check_and_log "V6" "https://[2606:4700:4700::1111]/cdn-cgi/trace" "$V6_FILE"; then
            if ! curl -s6 -m 5 "https://[2606:4700:4700::1001]/cdn-cgi/trace" >/dev/null 2>&1; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') | 🚨 IPv6 探测死锁，尝试唤醒 ($WARP_SRV)..." >> "$SYS_LOG"
                [ "$WARP_SRV" != "none" ] && systemctl restart "$WARP_SRV"
                sleep 15
            fi
        fi
    fi
done
EOF
chmod +x /usr/bin/w_dog
cat > /etc/systemd/system/warp-dog.service << 'EOF'
[Unit]
Description=Dual-Stack Time-Series Radar
After=network.target
[Service]
ExecStart=/usr/bin/w_dog
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now warp-dog >/dev/null 2>&1

# ================= 7. 天网大一统中控台 =================
echo -e "\n\033[1;35m🌌 正在构建天网大一统中控台 (st)...\033[0m"
cat << 'EOF' > /usr/bin/st
#!/bin/bash
while true; do
    source /etc/s-box/status.env
    clear
    echo -e "\033[1;36m==================================================================\033[0m"
    echo -e "\033[1;37m        🛡️ 极简单轨稳定版总控台 (V3.0 典藏版)      \033[0m"
    echo -e "\033[1;36m==================================================================\033[0m"
    
    MEM=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }' 2>/dev/null || echo "未知")
    CPU=$(top -bn1 2>/dev/null | grep load | awk '{printf "%.2f", $(NF-2)}' || echo "未知")
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
    
    V4_IP=$(curl -s4 -m 2 "https://1.1.1.1/cdn-cgi/trace" 2>/dev/null | grep "ip=" | cut -d= -f2)
    V6_IP=$(curl -s6 -m 2 "https://[2606:4700:4700::1111]/cdn-cgi/trace" 2>/dev/null | grep "ip=" | cut -d= -f2)
    
    [ -z "$V4_IP" ] && V4_DISP="\033[1;31m无 IPv4 路由或死锁\033[0m" || V4_DISP="\033[1;37m$V4_IP\033[0m"
    [ -z "$V6_IP" ] && V6_DISP="\033[1;31m无 IPv6 路由或死锁\033[0m" || V6_DISP="\033[1;37m$V6_IP\033[0m"
    
    if grep -q "^precedence ::ffff:0:0/96.*100" /etc/gai.conf 2>/dev/null; then
        PRIORITY_ST="\033[1;33mIPv4 优先\033[0m"
    else
        PRIORITY_ST="\033[1;32mIPv6 优先\033[0m"
    fi

    echo -e " 💻 宿主机: \033[1;37m${UPTIME}\033[0m | CPU: \033[1;37m$CPU\033[0m | 内存: \033[1;37m$MEM\033[0m"
    echo -e " 🔑 安全池: \033[1;32m动态随机 SNI (${HY2_SNI}) | 防火墙隐身就绪\033[0m"
    echo -e "------------------------------------------------------------------"
    echo -e " \033[1;35m>>> 🌐 双栈时序雷达矩阵 (实时获取) <<<\033[0m"
    echo -e "  * 当前出口 IPv4: $V4_DISP"
    echo -e "  * 当前出口 IPv6: $V6_DISP"
    echo -e " \033[1;90m [近期漂移追溯] (最多展示3条，详情见菜单 8)\033[0m"
    if [ -f /etc/s-box/drift.log ] && [ $(wc -l < /etc/s-box/drift.log) -gt 0 ]; then
        tail -n 3 /etc/s-box/drift.log | while read line; do echo -e "    \033[1;33m$line\033[0m"; done
    else
        echo -e "    \033[1;90m暂无 IP 漂移记录，您的网络非常稳定。\033[0m"
    fi
    echo -e "------------------------------------------------------------------"
    
    [ "$HY2_ON" = "1" ] && S1="\033[1;32m🟢 运行中\033[0m" || S1="\033[1;31m💤 休眠\033[0m"
    [ "$VLESS_ON" = "1" ] && S2="\033[1;32m🟢 运行中\033[0m" || S2="\033[1;31m💤 休眠\033[0m"
    [ "$VMESS_ON" = "1" ] && S3="\033[1;32m🟢 运行中\033[0m" || S3="\033[1;31m💤 休眠\033[0m"

    echo -e " \033[1;33m>>> 🛡️ 核心入站协议引擎 (全局直通出站) <<<\033[0m"
    echo -e "  [\033[1;36m1\033[0m] 切换 HY2    (公网UDP直连 8443)  | 状态: $S1"
    echo -e "  [\033[1;36m2\033[0m] 切换 VLESS  (Argo穿透绑定 10001) | 状态: $S2"
    echo -e "  [\033[1;36m3\033[0m] 切换 VMess  (Argo穿透绑定 10002) | 状态: $S3"
    echo -e "------------------------------------------------------------------"
    echo -e " \033[1;34m>>> ⚙️ 系统策略与工具 <<<\033[0m"
    echo -e "  [\033[1;36m4\033[0m] ☁️ Argo 隧道部署 & 专属域名自动化绑定"
    echo -e "  [\033[1;36m5\033[0m] 🔗 \033[1;32m提取所有直通节点 (自动填充高强度密钥与域名)\033[0m"
    echo -e "  [\033[1;36m6\033[0m] 🔀 切换双栈出站优先级 (当前: $PRIORITY_ST \033[1;90m| 实时重启生效\033[0m)"
    echo -e "  [\033[1;36m7\033[0m] 📜 追踪 Sing-box 实时底层日志"
    echo -e "  [\033[1;36m8\033[0m] 🕒 \033[1;35m查询完整 IP 漂移历史记录 (时序图)\033[0m"
    echo -e "  [\033[1;36m9\033[0m] ⚠️ 执行物理自毁程序 (卸载清理)"
    echo -e "  [\033[1;36m0\033[0m] 🚪 退出面板"
    echo -e "\033[1;36m==================================================================\033[0m"
    
    read -p "👉 请输入指令 (0-9): " CMD
    case $CMD in
        1) [ "$HY2_ON" = "1" ] && N=0 || N=1; sed -i "s/^HY2_ON=.*/HY2_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; systemctl restart sing-box; echo -e "\033[1;32m✅ 状态切换完毕并已重启生效！\033[0m"; sleep 1 ;;
        2) [ "$VLESS_ON" = "1" ] && N=0 || N=1; sed -i "s/^VLESS_ON=.*/VLESS_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; systemctl restart sing-box; echo -e "\033[1;32m✅ 状态切换完毕并已重启生效！\033[0m"; sleep 1 ;;
        3) [ "$VMESS_ON" = "1" ] && N=0 || N=1; sed -i "s/^VMESS_ON=.*/VMESS_ON=$N/" /etc/s-box/status.env; /usr/local/bin/sb_gen; systemctl restart sing-box; echo -e "\033[1;32m✅ 状态切换完毕并已重启生效！\033[0m"; sleep 1 ;;
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
            IP=$(curl -s4 -m 2 api.ipify.org 2>/dev/null || curl -s6 -m 2 api64.ipify.org 2>/dev/null)
            [ -z "$IP" ] && IP="获取原生IP失败_请检查网卡"
            
            D_V1=${DOMAIN_VLESS:-"未配置域名请替换"}
            D_M1=${DOMAIN_VMESS:-"未配置域名请替换"}
            
            echo ""
            if [ "$HY2_ON" = "1" ]; then echo -e "\033[1;35m[协议 1] HY2 (全局直连):\033[0m\n\033[40;32m hysteria2://$SYS_PW@$IP:8443/?sni=$HY2_SNI&insecure=1#Global-HY2 \033[0m\n"; fi
            if [ "$VLESS_ON" = "1" ]; then 
                echo -e "\033[1;35m[协议 2] VLESS (Argo穿透):\033[0m\n\033[40;32m vless://$SYS_UUID@$D_V1:443?encryption=none&security=tls&sni=$D_V1&type=ws&host=$D_V1&path=%2Fvless#Argo-VLESS \033[0m\n"
            fi
            if [ "$VMESS_ON" = "1" ]; then echo -e "\033[1;35m[协议 3] VMess (Argo穿透):\033[0m\n\033[40;32m vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"Argo-VMess\",\"add\":\"$D_M1\",\"port\":\"443\",\"id\":\"$SYS_UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$D_M1\",\"path\":\"/vmess\",\"tls\":\"tls\"}" | base64 -w 0) \033[0m\n"; fi
            read -n 1 -s -r -p "按任意键返回菜单..."
            ;;
        6)
            if grep -q "^precedence ::ffff:0:0/96.*100" /etc/gai.conf 2>/dev/null; then
                sed -i '/^precedence ::ffff:0:0\/96/d' /etc/gai.conf 2>/dev/null
                echo "precedence ::ffff:0:0/96  10" >> /etc/gai.conf
                echo -e "\n\033[1;32m✅ 切换成功！系统现已全局优先走 IPv6 出口。\033[0m"
            else
                sed -i '/^precedence ::ffff:0:0\/96/d' /etc/gai.conf 2>/dev/null
                echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
                echo -e "\n\033[1;32m✅ 切换成功！系统现已全局优先走 IPv4 出口 (防双栈卡死)。\033[0m"
            fi
            echo -e "\033[1;35m🔄 正在重新生成路由策略并重启核心...\033[0m"
            /usr/local/bin/sb_gen
            systemctl restart sing-box >/dev/null 2>&1
            sleep 2
            ;;
        7) echo -e "\033[1;36m📜 追踪底层日志 (Ctrl+C 退出)...\033[0m"; journalctl -u sing-box --no-pager --output cat -f -n 50 ;;
        8) 
            clear
            echo -e "\033[1;36m==================================================================\033[0m"
            echo -e "\033[1;33m                      🕒 完整 IP 漂移历史记录图                    \033[0m"
            echo -e "\033[1;36m==================================================================\033[0m"
            if [ -f /etc/s-box/drift.log ] && [ $(wc -l < /etc/s-box/drift.log) -gt 0 ]; then
                cat /etc/s-box/drift.log | while read line; do
                    if echo "$line" | grep -q "V4"; then
                        echo -e " \033[1;34m$line\033[0m"
                    else
                        echo -e " \033[1;32m$line\033[0m"
                    fi
                done
            else
                echo -e " \033[1;90m暂无任何漂移记录。\033[0m"
            fi
            echo -e "\033[1;36m==================================================================\033[0m"
            read -n 1 -s -r -p "按任意键返回主菜单..."
            ;;
        9)
            echo -e "\033[1;31m⚠️ 正在执行物理卸载...\033[0m"
            systemctl stop sing-box cloudflared warp-dog 2>/dev/null
            systemctl disable --now sing-box cloudflared warp-dog 2>/dev/null
            rm -rf /etc/s-box /usr/local/bin/sb_gen /usr/local/bin/cloudflared /etc/systemd/system/cloudflared.service /etc/systemd/system/sing-box.service /etc/systemd/system/warp-dog.service /usr/bin/w_dog /usr/bin/st
            sed -i '/^precedence ::ffff:0:0\/96/d' /etc/gai.conf 2>/dev/null
            systemctl daemon-reload
            echo -e "\033[1;32m🎉 彻底物理卸载完毕！核心组件已清除 (未卸载基础 WARP)。\033[0m"; exit 0
            ;;
        0) clear; exit 0 ;;
        *) echo -e "\033[1;31m❌ 无效指令！\033[0m"; sleep 1 ;;
    esac
done
EOF
chmod +x /usr/bin/st

echo -e "\n\033[1;32m🎉 极简单轨稳定版 V3.0 (典藏版) 部署完毕！\033[0m"
echo -e "\033[1;37m👉 请在终端输入 \033[1;33mst\033[1;37m 呼出天网大一统中控台！\033[0m"
