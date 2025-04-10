#!/bin/bash

# =============================================
# QY-BERN ULTIMATE SYSTEM MONITOR PRO BY NULLH3XX V1.0
# =============================================
# Wraited by NullH3xx : Abderrahmane Idrissi
# GitHub: https://github.com/Nullh3xx
# Linkedin: https://Linkedin.com/in/abderrahmane-idrissi-mesbahi-725b88237
# instagram: https://instagram.com/nullh3xx

# --------------
# CONFIGURATION
# --------------
CONFIG_FILE="/etc/nullhexx_monitor.conf"
TELEGRAM_TOKEN=""
TELEGRAM_CHAT_ID=""
LOG_FILE="/var/log/nullhexx_monitor.log"
SERVICE_FILE="/etc/systemd/system/nullhexx-monitor.service"
SCRIPT_PATH=$(realpath "$0")
OTP_CODE=$(shuf -i 100000-999999 -n 1)
MONITOR_INTERVAL=60  # Default monitoring interval

# CYBERPUNK COLOR PALETTE
NC='\033[0m'
BLACK='\033[0;30m'
RED='\033[0;38;5;196m'
GREEN='\033[0;38;5;46m'
YELLOW='\033[0;38;5;226m'
BLUE='\033[0;38;5;39m'
PURPLE='\033[0;38;5;129m'
CYAN='\033[0;38;5;51m'
WHITE='\033[1;37m'
BOLD='\033[1m'
BLINK='\033[5m'
MATRIX_GREEN='\033[0;38;5;118m'
HACKER_PURPLE='\033[0;38;5;93m'
TERMINAL_ORANGE='\033[0;38;5;208m'
NEON_PINK='\033[0;38;5;200m'
NEON_BLUE='\033[0;38;5;45m'

# DEFAULT THRESHOLDS
CPU_WARN=70    CPU_CRIT=90
RAM_WARN=70    RAM_CRIT=90
DISK_WARN=80   DISK_CRIT=95
TEMP_WARN=70   TEMP_CRIT=85

# -----------------
# LOAD CONFIG FILE
# -----------------
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "[$(date)] Config loaded from $CONFIG_FILE" >> "$LOG_FILE"
    else
        echo "[$(date)] WARNING: Config file not found at $CONFIG_FILE" >> "$LOG_FILE"
    fi
}

# -----------------
# SYSTEM STATS COLLECTION
# -----------------
get_stats() {
    # CPU Usage (more robust parsing)
    CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # RAM Usage
    RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
    RAM_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($RAM_USED / $RAM_TOTAL) * 100}")
    
    # Disk Usage
    DISK=$(df -h / | awk '/\// {print $5}' | tr -d '%')
    
    # Temperature (with fallback)
    TEMP_PATH=$(ls /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n1)
    if [ -n "$TEMP_PATH" ]; then
        TEMP=$(($(cat $TEMP_PATH) / 1000))
    else
        TEMP=0
    fi
    
    # Network Usage
    INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
    if [ -n "$INTERFACE" ]; then
        RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
        TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
        sleep 1
        RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
        TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
        NET_DOWN=$(( (RX2 - RX1) / 1024 ))
        NET_UP=$(( (TX2 - TX1) / 1024 ))
    else
        NET_DOWN=0
        NET_UP=0
    fi
}

# -----------------
# ENHANCED TELEGRAM ALERT FUNCTION
# -----------------
send_alert() {
    local title=$1
    local message=$2
    local current_time=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Load config in case running as service
    load_config
    
    # Verify required variables
    if [[ -z "$TELEGRAM_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
        echo "[$(date)] ERROR: Missing Telegram credentials" >> "$LOG_FILE"
        return 1
    fi

    # Add timestamp to message
    message="🕒 *Time:* $current_time\n$message"

    # Try sending with detailed error logging
    for i in {1..3}; do
        response=$(timeout 10 curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"chat_id":"'"$TELEGRAM_CHAT_ID"'", "text":"'"$title\n$message"'", "parse_mode":"Markdown"}' \
            "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" 2>&1)
        
        if [[ "$response" == *"\"ok\":true"* ]]; then
            echo "[$(date)] Alert sent successfully" >> "$LOG_FILE"
            return 0
        else
            echo "[$(date)] Attempt $i failed: ${response:-No response}" >> "$LOG_FILE"
            sleep 2
        fi
    done
    
    echo "[$(date)] CRITICAL: Failed to send alert after 3 attempts" >> "$LOG_FILE"
    return 1
}

# -----------------
# PROGRESS BAR ANIMATION
# -----------------
show_progress() {
    local duration=${1}
    local width=50
    local increment=$((100/width))
    
    for ((i=0; i<=width; i++)); do
        percentage=$((i*increment))
        bar="["
        for ((j=0; j<i; j++)); do bar+="▓"; done
        for ((j=i; j<width; j++)); do bar+="░"; done
        bar+="] $percentage%"
        
        printf "\r${BLUE}%s${NC}" "$bar"
        sleep "$duration"
    done
    printf "\n"
}


# -----------------
#  INPUT BOX 
# -----------------
input_box() {
    local title=$1
    local prompt=$2
    local example=$3
    
    echo -e "${BLUE}┌──────────────────────────────────────────────────────┐"
    echo -e "│ ${CYAN}$title ${BLUE}│"
    echo -e "├──────────────────────────────────────────────────────┤"
    echo -e "│ ${MATRIX_GREEN}$prompt${BLUE}│"
    [ -n "$example" ] && echo -e "│ ${YELLOW}$example${BLUE}│"
    echo -e "└──────────────────────────────────────────────────────┘${NC}"
    echo -en "${TERMINAL_ORANGE}» ${NC}"
}

# -----------------
# MATRIX-STYLE OPENING ANIMATION
# -----------------
matrix_animation() {
    clear
    echo -e "${MATRIX_GREEN}"
    cols=$(tput cols)
    
    # Center the animation
    printf "%*s\n" $((cols/2 - 15)) " "
    printf "%*s\n" $((cols/2 - 15)) " ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░░▒▓████████▓▒░▒▓███████▓▒░░▒▓███████▓▒░  "
    printf "%*s\n" $((cols/2 - 15)) "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    printf "%*s\n" $((cols/2 - 15)) "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    printf "%*s\n" $((cols/2 - 15)) "░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░ "
    printf "%*s\n" $((cols/2 - 15)) "░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    printf "%*s\n" $((cols/2 - 15)) "░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    printf "%*s\n" $((cols/2 - 15)) " ░▒▓██████▓▒░   ░▒▓█▓▒░   ░▒▓███████▓▒░░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    printf "%*s\n" $((cols/2 - 15)) "   ░▒▓█▓▒░                                                                      "
    printf "%*s\n" $((cols/2 - 15)) "    ░▒▓██▓▒░                                                                    "
    printf "%*s\n" $((cols/2 - 15)) " "
    
    echo -ne "Initializing NULLHEXX Monitor "
    spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    for i in {1..3}; do
        for s in "${spinner[@]}"; do
            printf "${MATRIX_GREEN}%s${NC}" "$s"
            sleep 0.1
            printf "\b"
        done
    done
    
    show_progress 0.02
    clear
}

# -----------------
# CYBERPUNK BANNER
# -----------------
show_banner() {
    clear
    echo -e "${HACKER_PURPLE}"
    echo -e " ░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    echo -e " ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    echo -e " ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    echo -e " ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓████████▓▒░▒▓██████▓▒░  ░▒▓██████▓▒░ ░▒▓██████▓▒░  "
    echo -e " ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    echo -e " ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    echo -e " ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓████████▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ "
    echo -e "${BLUE}┌──────────────────────────────────────────────────────┐"
    echo -e "│ ${CYAN}🛡  QYBERN ULTIMATE SYSTEM MONITOR ${TERMINAL_ORANGE}v1.0 ${BLUE}           │"
    echo -e "└──────────────────────────────────────────────────────┘${NC}"
}

# -----------------
# TELEGRAM OTP VERIFICATION
# -----------------
verify_telegram() {
    # Send OTP with beautiful formatting
    send_alert "🔐 *QYBERN VERIFICATION* 🔐" "
╔══════════════════════╗
║   *OTP CODE*         ║
║                      ║
║      $OTP_CODE       ║
║                      ║
║ Enter this code to   ║
║ verify your identity ║
╚══════════════════════╝"
    
    # Verification loop
    attempts=0
    max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        input_box "OTP VERIFICATION" "Enter the 6-digit code sent to your Telegram:" "Example: 123456"
        read -r user_otp
        
        if [ "$user_otp" == "$OTP_CODE" ]; then
            echo -e "\n${GREEN}╔══════════════════════╗"
            echo -e "║   VERIFICATION       ║"
            echo -e "║      SUCCESSFUL!     ║"
            echo -e "╚══════════════════════╝${NC}"
            sleep 1
            
            # Save config
            echo "TELEGRAM_TOKEN=\"$TELEGRAM_TOKEN\"" > "$CONFIG_FILE"
            echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$CONFIG_FILE"
            echo "CPU_WARN=$CPU_WARN" >> "$CONFIG_FILE"
            echo "CPU_CRIT=$CPU_CRIT" >> "$CONFIG_FILE"
            echo "RAM_WARN=$RAM_WARN" >> "$CONFIG_FILE"
            echo "RAM_CRIT=$RAM_CRIT" >> "$CONFIG_FILE"
            echo "DISK_WARN=$DISK_WARN" >> "$CONFIG_FILE"
            echo "DISK_CRIT=$DISK_CRIT" >> "$CONFIG_FILE"
            echo "TEMP_WARN=$TEMP_WARN" >> "$CONFIG_FILE"
            echo "TEMP_CRIT=$TEMP_CRIT" >> "$CONFIG_FILE"
            echo "MONITOR_INTERVAL=$MONITOR_INTERVAL" >> "$CONFIG_FILE"
            
            return 0
        else
            attempts=$((attempts + 1))
            remaining=$((max_attempts - attempts))
            echo -e "\n${RED}╔══════════════════════╗"
            echo -e "║   INVALID CODE!      ║"
            echo -e "║  $remaining attempts remaining ║"
            echo -e "╚══════════════════════╝${NC}"
            sleep 1
            
            if [ $attempts -lt $max_attempts ]; then
                OTP_CODE=$(shuf -i 100000-999999 -n 1)
                send_alert "🔐 *NEW OTP CODE* 🔐" "
╔══════════════════════╗
║   *NEW OTP CODE*     ║
║                      ║
║      $OTP_CODE       ║
║                      ║
║ Enter this new code  ║
╚══════════════════════╝"
            fi
        fi
    done
    
    echo -e "\n${RED}╔══════════════════════╗"
    echo -e "║   VERIFICATION       ║"
    echo -e "║      FAILED!         ║"
    echo -e "╚══════════════════════╝${NC}"
    sleep 2
    return 1
}

# -----------------
# ANIMATED THRESHOLD INPUT
# -----------------
setup_thresholds() {
    echo -e "\n${BLUE}┌──────────────────────────────────────────────────────┐"
    echo -e "│ ${CYAN}⚙  CONFIGURE ALERT THRESHOLDS ${BLUE}                  │"
    echo -e "└──────────────────────────────────────────────────────┘${NC}"
    
    # Show current values with animation
    echo -e "\n${NEON_PINK}Current Threshold Values:${NC}"
    echo -ne "${NEON_BLUE}CPU:    " && for ((i=0; i<=$CPU_WARN; i++)); do echo -ne "▮"; sleep 0.01; done && echo -e " ${CPU_WARN}% Warning${NC}"
    echo -ne "${NEON_PINK}        " && for ((i=0; i<=$CPU_CRIT; i++)); do echo -ne "▮"; sleep 0.01; done && echo -e " ${CPU_CRIT}% Critical${NC}"
    
    echo -ne "${NEON_BLUE}RAM:    " && for ((i=0; i<=$RAM_WARN; i++)); do echo -ne "▮"; sleep 0.01; done && echo -e " ${RAM_WARN}% Warning${NC}"
    echo -ne "${NEON_PINK}        " && for ((i=0; i<=$RAM_CRIT; i++)); do echo -ne "▮"; sleep 0.01; done && echo -e " ${RAM_CRIT}% Critical${NC}"
    
    echo -ne "${NEON_BLUE}Disk:   " && for ((i=0; i<=$DISK_WARN; i++)); do echo -ne "▮"; sleep 0.01; done && echo -e " ${DISK_WARN}% Warning${NC}"
    echo -ne "${NEON_PINK}        " && for ((i=0; i<=$DISK_CRIT; i++)); do echo -ne "▮"; sleep 0.01; done && echo -e " ${DISK_CRIT}% Critical${NC}"
    
    echo -ne "${NEON_BLUE}Temp:   " && for ((i=0; i<=$TEMP_WARN; i++)); do echo -ne "▮"; sleep 0.01; done && echo -e " ${TEMP_WARN}°C Warning${NC}"
    echo -ne "${NEON_PINK}        " && for ((i=0; i<=$TEMP_CRIT; i++)); do echo -ne "▮"; sleep 0.01; done && echo -e " ${TEMP_CRIT}°C Critical${NC}"
    
    input_box "THRESHOLD SETUP" "Would you like to configure custom thresholds? (y/n)" "type (y) for custom, (n) for defaults"
    read -r custom_thresholds
    
    if [[ "$custom_thresholds" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Enter custom threshold values (must be numbers between 1-100):${NC}"
        
        # CPU Thresholds with animated input
        echo -e "\n${NEON_BLUE}┌──────────────────────────────────────────────────────┐"
        echo -e "│ ${CYAN}💻 CPU THRESHOLDS ${NEON_BLUE}                                   │"
        echo -e "└──────────────────────────────────────────────────────┘${NC}"
        while true; do
            input_box "CPU WARNING THRESHOLD" "Enter CPU warning threshold (%):" "Default: 70"
            read -r CPU_WARN
            if [[ "$CPU_WARN" =~ ^[0-9]+$ ]] && [ "$CPU_WARN" -ge 1 ] && [ "$CPU_WARN" -le 100 ]; then
                echo -ne "${GREEN}Setting CPU Warning: " && for ((i=0; i<=$CPU_WARN; i++)); do echo -ne "▮"; sleep 0.005; done && echo -e " ${CPU_WARN}%${NC}"
                break
            else
                echo -e "${RED}✗ Invalid input! Please enter a number between 1-100.${NC}"
            fi
        done
        
        while true; do
            input_box "CPU CRITICAL THRESHOLD" "Enter CPU critical threshold (%):" "Must be > $CPU_WARN, Default: 90"
            read -r CPU_CRIT
            if [[ "$CPU_CRIT" =~ ^[0-9]+$ ]] && [ "$CPU_CRIT" -gt "$CPU_WARN" ] && [ "$CPU_CRIT" -le 100 ]; then
                echo -ne "${RED}Setting CPU Critical: " && for ((i=0; i<=$CPU_CRIT; i++)); do echo -ne "▮"; sleep 0.005; done && echo -e " ${CPU_CRIT}%${NC}"
                break
            else
                echo -e "${RED}✗ Invalid input! Must be greater than warning threshold ($CPU_WARN) and ≤100.${NC}"
            fi
        done
        
        # RAM Thresholds with animated input
        echo -e "\n${NEON_PINK}┌──────────────────────────────────────────────────────┐"
        echo -e "│ ${CYAN}🧠 RAM THRESHOLDS ${NEON_PINK}                                   │"
        echo -e "└──────────────────────────────────────────────────────┘${NC}"
        while true; do
            input_box "RAM WARNING THRESHOLD" "Enter RAM warning threshold (%):" "Default: 70"
            read -r RAM_WARN
            if [[ "$RAM_WARN" =~ ^[0-9]+$ ]] && [ "$RAM_WARN" -ge 1 ] && [ "$RAM_WARN" -le 100 ]; then
                echo -ne "${GREEN}Setting RAM Warning: " && for ((i=0; i<=$RAM_WARN; i++)); do echo -ne "▮"; sleep 0.005; done && echo -e " ${RAM_WARN}%${NC}"
                break
            else
                echo -e "${RED}✗ Invalid input! Please enter a number between 1-100.${NC}"
            fi
        done
        
        while true; do
            input_box "RAM CRITICAL THRESHOLD" "Enter RAM critical threshold (%):" "Must be > $RAM_WARN, Default: 90"
            read -r RAM_CRIT
            if [[ "$RAM_CRIT" =~ ^[0-9]+$ ]] && [ "$RAM_CRIT" -gt "$RAM_WARN" ] && [ "$RAM_CRIT" -le 100 ]; then
                echo -ne "${RED}Setting RAM Critical: " && for ((i=0; i<=$RAM_CRIT; i++)); do echo -ne "▮"; sleep 0.005; done && echo -e " ${RAM_CRIT}%${NC}"
                break
            else
                echo -e "${RED}✗ Invalid input! Must be greater than warning threshold ($RAM_WARN) and ≤100.${NC}"
            fi
        done
        
        # Disk Thresholds with animated input
        echo -e "\n${TERMINAL_ORANGE}┌──────────────────────────────────────────────────────┐"
        echo -e "│ ${CYAN}💾 DISK THRESHOLDS ${TERMINAL_ORANGE}                               │"
        echo -e "└──────────────────────────────────────────────────────┘${NC}"
        while true; do
            input_box "DISK WARNING THRESHOLD" "Enter Disk warning threshold (%):" "Default: 80"
            read -r DISK_WARN
            if [[ "$DISK_WARN" =~ ^[0-9]+$ ]] && [ "$DISK_WARN" -ge 1 ] && [ "$DISK_WARN" -le 100 ]; then
                echo -ne "${GREEN}Setting Disk Warning: " && for ((i=0; i<=$DISK_WARN; i++)); do echo -ne "▮"; sleep 0.005; done && echo -e " ${DISK_WARN}%${NC}"
                break
            else
                echo -e "${RED}✗ Invalid input! Please enter a number between 1-100.${NC}"
            fi
        done
        
        while true; do
            input_box "DISK CRITICAL THRESHOLD" "Enter Disk critical threshold (%):" "Must be > $DISK_WARN, Default: 95"
            read -r DISK_CRIT
            if [[ "$DISK_CRIT" =~ ^[0-9]+$ ]] && [ "$DISK_CRIT" -gt "$DISK_WARN" ] && [ "$DISK_CRIT" -le 100 ]; then
                echo -ne "${RED}Setting Disk Critical: " && for ((i=0; i<=$DISK_CRIT; i++)); do echo -ne "▮"; sleep 0.005; done && echo -e " ${DISK_CRIT}%${NC}"
                break
            else
                echo -e "${RED}✗ Invalid input! Must be greater than warning threshold ($DISK_WARN) and ≤100.${NC}"
            fi
        done
        
        # Temp Thresholds with animated input
        echo -e "\n${MATRIX_GREEN}┌──────────────────────────────────────────────────────┐"
        echo -e "│ ${CYAN}🌡 TEMPERATURE THRESHOLDS ${MATRIX_GREEN}                         │"
        echo -e "└──────────────────────────────────────────────────────┘${NC}"
        while true; do
            input_box "TEMP WARNING THRESHOLD" "Enter Temperature warning threshold (°C):" "Default: 70"
            read -r TEMP_WARN
            if [[ "$TEMP_WARN" =~ ^[0-9]+$ ]] && [ "$TEMP_WARN" -ge 1 ] && [ "$TEMP_WARN" -le 120 ]; then
                echo -ne "${GREEN}Setting Temp Warning: " && for ((i=0; i<=$TEMP_WARN; i++)); do echo -ne "▮"; sleep 0.005; done && echo -e " ${TEMP_WARN}°C${NC}"
                break
            else
                echo -e "${RED}✗ Invalid input! Please enter a number between 1-120.${NC}"
            fi
        done
        
        while true; do
            input_box "TEMP CRITICAL THRESHOLD" "Enter Temperature critical threshold (°C):" "Must be > $TEMP_WARN, Default: 85"
            read -r TEMP_CRIT
            if [[ "$TEMP_CRIT" =~ ^[0-9]+$ ]] && [ "$TEMP_CRIT" -gt "$TEMP_WARN" ] && [ "$TEMP_CRIT" -le 120 ]; then
                echo -ne "${RED}Setting Temp Critical: " && for ((i=0; i<=$TEMP_CRIT; i++)); do echo -ne "▮"; sleep 0.005; done && echo -e " ${TEMP_CRIT}°C${NC}"
                break
            else
                echo -e "${RED}✗ Invalid input! Must be greater than warning threshold ($TEMP_WARN) and ≤120.${NC}"
            fi
        done
        
        echo -e "\n${GREEN}✓ Custom thresholds configured successfully!${NC}"
    else
        echo -e "\n${YELLOW}Using default threshold values.${NC}"
    fi
}

# -----------------
# MONITOR INTERVAL SETUP
# -----------------
setup_monitor_interval() {
    echo -e "\n${BLUE}┌──────────────────────────────────────────────────────┐"
    echo -e "│ ${CYAN}⏱  CONFIGURE MONITORING INTERVAL ${BLUE}              │"
    echo -e "└──────────────────────────────────────────────────────┘${NC}"
    
    echo -e "\n${YELLOW}Current monitoring interval: ${MONITOR_INTERVAL} seconds${NC}"
    
    input_box "MONITOR INTERVAL" "Would you like to change the monitoring interval? (y/n)" "type (y) to change, (n) to keep ${MONITOR_INTERVAL} seconds"
    read -r change_interval
    
    if [[ "$change_interval" =~ ^[Yy]$ ]]; then
        while true; do
            input_box "MONITOR INTERVAL" "Enter monitoring interval in seconds (10-3600):" "Default: 60"
            read -r MONITOR_INTERVAL
            
            if [[ "$MONITOR_INTERVAL" =~ ^[0-9]+$ ]] && [ "$MONITOR_INTERVAL" -ge 10 ] && [ "$MONITOR_INTERVAL" -le 3600 ]; then
                echo -e "\n${GREEN}✓ Monitoring interval set to ${MONITOR_INTERVAL} seconds${NC}"
                
                # Animate the new interval setting
                echo -ne "${NEON_BLUE}Setting interval: "
                for i in {1..10}; do
                    echo -ne "⏱ ${MONITOR_INTERVAL}s "
                    sleep 0.1
                    printf "\r"
                    echo -ne "          "
                    printf "\r"
                done
                echo -e "⏱ ${NEON_BLUE}Monitoring every ${MONITOR_INTERVAL} seconds${NC}"
                
                break
            else
                echo -e "${RED}✗ Invalid input! Please enter a number between 10-3600.${NC}"
            fi
        done
    else
        echo -e "\n${YELLOW}Keeping default monitoring interval of ${MONITOR_INTERVAL} seconds.${NC}"
    fi
}

# -----------------
# REUSABLE TELEGRAM CONFIG
# -----------------
setup_telegram() {
    # Check if config exists
    if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
        echo -e "\n${BLUE}┌──────────────────────────────────────────────────────┐"
        echo -e "│ ${CYAN}🔍 EXISTING TELEGRAM CONFIG FOUND ${BLUE}                │"
        echo -e "└──────────────────────────────────────────────────────┘${NC}"
        
        source "$CONFIG_FILE"
        
        echo -e "\n${YELLOW}Previous Telegram configuration detected:${NC}"
        echo -e "\n${GREEN}[Bot Token: ${TELEGRAM_TOKEN:0:4}...${TELEGRAM_TOKEN: -4}]"
        echo -e "\n${GREEN}[Chat ID: $TELEGRAM_CHAT_ID] "
        
        input_box "TELEGRAM CONFIG" "Would you like to use existing Telegram config? (y/n)" "type (y) to reuse, (n) to setup new"
        read -r reuse_config
        
        if [[ "$reuse_config" =~ ^[Yy]$ ]]; then
            echo -e "\n${GREEN}Using existing Telegram configuration.${NC}"
            return 0
        fi
    fi
    
    # Telegram Setup with validation
    while true; do
        input_box "TELEGRAM BOT TOKEN" "Enter your Telegram Bot Token:" "Format: 123456789:ABCdef_GHIJKLmnopQRSTUVwxyz"
        read -r TELEGRAM_TOKEN
        
        input_box "TELEGRAM CHAT ID" "Enter your Telegram Chat ID:" "Format: Numeric ID (like 123456789)"
        read -r TELEGRAM_CHAT_ID
        
        # Immediate connection test
        echo -e "\n${YELLOW}Testing Telegram connection...${NC}"
        if send_alert "🔌 *QYBERN CONNECTION TEST*" "╔══════════════════════╗\n║   CONNECTION TEST    ║\n╚══════════════════════╝"; then
            echo -e "${GREEN}✓ Telegram connection successful!${NC}"
            break
        else
            echo -e "${RED}✗ Failed to connect to Telegram${NC}"
            echo -e "${YELLOW}Please verify your Token and Chat ID${NC}"
            sleep 2
        fi
    done
    
    verify_telegram || return 1
}

# -----------------
# MAIN MONITOR FUNCTION
# -----------------
start_monitoring() {
    echo -e "\n${GREEN}Starting real-time monitoring...${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Alerts active - Thresholds: CPU($CPU_WARN/$CPU_CRIT) RAM($RAM_WARN/$RAM_CRIT)${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Monitoring interval: ${MONITOR_INTERVAL} seconds${NC}" | tee -a "$LOG_FILE"
    
    while true; do
        load_config
        get_stats
        
        # Enhanced CPU Alert with logging
        if (( $(echo "$CPU >= $CPU_CRIT" | bc -l) )); then
            echo "[$(date)] CPU CRITICAL: $CPU%" >> "$LOG_FILE"
            send_alert "🚨 *CPU CRITICAL* 🚨" "
╔══════════════════════╗
║   CPU USAGE: $CPU%     ║
║                      ║
║  CRITICAL THRESHOLD  ║
║        EXCEEDED!     ║
╚══════════════════════╝" || echo "[$(date)] Retrying CPU alert..." >> "$LOG_FILE"
        elif (( $(echo "$CPU >= $CPU_WARN" | bc -l) )); then
            echo "[$(date)] CPU Warning: $CPU%" >> "$LOG_FILE"
            send_alert "⚠ *CPU WARNING* ⚠" "
╔══════════════════════╗
║   CPU USAGE: $CPU%     ║
║                      ║
║   WARNING THRESHOLD  ║
║        EXCEEDED!     ║
╚══════════════════════╝" || echo "[$(date)] Retrying CPU warning..." >> "$LOG_FILE"
        fi
        
        # RAM Alerts
        if (( $(echo "$RAM_PERCENT >= $RAM_CRIT" | bc -l) )); then
            send_alert "🚨 *RAM CRITICAL* 🚨" "
╔══════════════════════╗
║   RAM USAGE: $RAM_PERCENT%   ║
║                      ║
║  CRITICAL THRESHOLD  ║
║        EXCEEDED!     ║
╚══════════════════════╝"
        elif (( $(echo "$RAM_PERCENT >= $RAM_WARN" | bc -l) )); then
            send_alert "⚠ *RAM WARNING* ⚠" "
╔══════════════════════╗
║   RAM USAGE: $RAM_PERCENT%   ║
║                      ║
║   WARNING THRESHOLD  ║
║        EXCEEDED!     ║
╚══════════════════════╝"
        fi
        
        # Disk Alerts
        if (( $(echo "$DISK >= $DISK_CRIT" | bc -l) )); then
            send_alert "🚨 *DISK CRITICAL* 🚨" "
╔══════════════════════╗
║   DISK USAGE: $DISK%    ║
║                      ║
║  CRITICAL THRESHOLD  ║
║        EXCEEDED!     ║
╚══════════════════════╝"
        elif (( $(echo "$DISK >= $DISK_WARN" | bc -l) )); then
            send_alert "⚠ *DISK WARNING* ⚠" "
╔══════════════════════╗
║   DISK USAGE: $DISK%    ║
║                      ║
║   WARNING THRESHOLD  ║
║        EXCEEDED!     ║
╚══════════════════════╝"
        fi
        
        # Temp Alerts
        if (( $(echo "$TEMP >= $TEMP_CRIT" | bc -l) )); then
            send_alert "🔥 *TEMP CRITICAL* 🔥" "
╔══════════════════════╗
║   TEMPERATURE: $TEMP°C  ║
║                      ║
║  CRITICAL THRESHOLD  ║
║        EXCEEDED!     ║
╚══════════════════════╝"
        elif (( $(echo "$TEMP >= $TEMP_WARN" | bc -l) )); then
            send_alert "🌡 *TEMP WARNING* 🌡" "
╔══════════════════════╗
║   TEMPERATURE: $TEMP°C  ║
║                      ║
║   WARNING THRESHOLD  ║
║        EXCEEDED!     ║
╚══════════════════════╝"
        fi
        
        sleep $MONITOR_INTERVAL
    done
}

# -----------------
# BACKGROUND SERVICE SETUP
# -----------------
setup_background_service() {
    echo -e "${BLUE}┌──────────────────────────────────────────────────────┐"
    echo -e "│ ${CYAN}⚙  CONFIGURING BACKGROUND SERVICE ${BLUE}              │"
    echo -e "└──────────────────────────────────────────────────────┘${NC}"
    
    # Create systemd service file with enhanced reliability
    sudo bash -c "cat > '$SERVICE_FILE'" <<EOL
[Unit]
Description=NULLHEXX System Monitor
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Type=simple
ExecStart=/bin/bash -c 'source /etc/nullhexx_monitor.conf; $SCRIPT_PATH --daemon'
Restart=always
RestartSec=5
User=root
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
WorkingDirectory=$(dirname "$SCRIPT_PATH")
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOL

    # Reload and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable nullhexx-monitor >/dev/null 2>&1
    sudo systemctl restart nullhexx-monitor >/dev/null 2>&1
    
    # Verify service is running
    if systemctl is-active --quiet nullhexx-monitor; then
        echo -e "${GREEN}✓ Background service installed and running${NC}"
        echo -e "${YELLOW}To check status: systemctl status nullhexx-monitor${NC}"
    else
        echo -e "${RED}✗ Failed to start background service${NC}" >&2
        echo -e "${YELLOW}Check logs: journalctl -u nullhexx-monitor${NC}" >&2
        exit 1
    fi
}

# -----------------
# MAIN EXECUTION
# -----------------
case "$1" in
    "--daemon")
        # Background mode - called by systemd
        echo "[$(date)] Starting NULLHEXX Monitor Daemon" >> "$LOG_FILE"
        start_monitoring
        ;;
    *)
        # Interactive mode
        matrix_animation
        show_banner
        
        # Setup Telegram (with reusable config check)
        setup_telegram || exit 1
        
        # Setup Thresholds with pro animations
        setup_thresholds
        
        # Setup Monitoring Interval
        setup_monitor_interval
        
        # Setup background service
        setup_background_service

        # Final status display
        echo -e "\n${BLUE}┌──────────────────────────────────────────────────────┐"
        echo -e "│ ${CYAN}🛡  NULLHEXX MONITOR ACTIVE ${BLUE}                      │"
        echo -e "├──────────────────────────────────────────────────────┤"
        echo -e "│ ${MATRIX_GREEN}Status:  ${GREEN}RUNNING${BLUE}                                   │"
        echo -e "│ ${MATRIX_GREEN}Alerts:  ${GREEN}ACTIVE${BLUE} (Telegram connected)               │"
        echo -e "│ ${MATRIX_GREEN}CPU:     ${YELLOW}Alerts at ${CPU_WARN}%/${CPU_CRIT}%${BLUE}                │"
        echo -e "│ ${MATRIX_GREEN}RAM:     ${YELLOW}Alerts at ${RAM_WARN}%/${RAM_CRIT}%${BLUE}                │"
        echo -e "│ ${MATRIX_GREEN}Storage: ${YELLOW}Alerts at ${DISK_WARN}%/${DISK_CRIT}%${BLUE}              │"
        echo -e "│ ${MATRIX_GREEN}Temp:    ${YELLOW}Alerts at ${TEMP_WARN}°C/${TEMP_CRIT}°C${BLUE}           │"
        echo -e "│ ${MATRIX_GREEN}Interval:${YELLOW} ${MONITOR_INTERVAL} seconds${BLUE}                      │"
        echo -e "└──────────────────────────────────────────────────────┘${NC}"
        
        echo -e "\n${YELLOW}The monitor is now running in the background.${NC}"
        echo -e "${YELLOW}To check status: systemctl status nullhexx-monitor${NC}"
        echo -e "${YELLOW}To view logs: journalctl -u nullhexx-monitor -f${NC}"
        
        show_credits() {
    echo -e "\n"
    echo -e "${BLUE}┌──────────────────────────────────────────────────────┐"
    echo -e "│ ${CYAN}🛠  Qybern v1.0 - Quantum System Monitor ${BLUE}         │"
    echo -e "├──────────────────────────────────────────────────────┤"
    echo -e "│ ${GREEN}Coded by ${RED}NullH3xx${BLUE}                                   │"
    echo -e "│ ${GREEN}Location: ${YELLOW}Moroccan, Fes${BLUE}                     │"
    echo -e "└──────────────────────────────────────────────────────┘${NC}"
    echo -e "\n"
}
show_credits
        exit 0
        ;;
esac
