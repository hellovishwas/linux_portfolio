#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
SNAPSHOT_DIR="$SCRIPT_DIR/../snapshots"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: config.conf not found."
    exit 1
fi

get_color() {
	local usage=$1

	if (( $(echo "$usage >= $CRITICAL_THRESHOLD" | bc -l) )); then
		echo "$RED"
	elif (( $(echo "$usage >= $WARNING_THRESHOLD " | bc -l) )); then
        	echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

get_status() {
	local usage=$1

	if (( $(echo "$usage >= $CRITICAL_THRESHOLD" | bc -l) )); then
		echo "CRITICAL"
	elif (( $(echo "$usage >= $WARNING_THRESHOLD" | bc -l) )); then
		echo "WARNING"
	else
		echo "HEALTHY"
	fi
}

get_overall_status() {
    local cpu=$1
    local ram=$2
    local disk=$3

    if (( $(echo "$cpu >= $CRITICAL_THRESHOLD" | bc -l) )) ||
       (( $(echo "$ram >= $CRITICAL_THRESHOLD" | bc -l) )) ||
       (( $(echo "$disk >= $CRITICAL_THRESHOLD" | bc -l) )); then
        return 2
    fi

    if (( $(echo "$cpu >= $WARNING_THRESHOLD" | bc -l) )) ||
       (( $(echo "$ram >= $WARNING_THRESHOLD" | bc -l) )) ||
       (( $(echo "$disk >= $WARNING_THRESHOLD" | bc -l) )); then
        return 1
    fi

    return 0
}

get_alert() {
    local metric=$1
    local usage=$2

    if (( $(echo "$usage >= $CRITICAL_THRESHOLD" | bc -l) )); then
        echo "CRITICAL: $metric usage is very high: ${usage}%"
    elif (( $(echo "$usage >= $WARNING_THRESHOLD" | bc -l) )); then
        echo "WARNING: $metric usage is high: ${usage}%"
    fi
}

progress_bar() {
    local usage=$(echo "$1" | grep -oE '[0-9]+(\.[0-9]+)?' | head -n1)
    local total=20

    if [ -z "$usage" ]; then usage=0; fi

    local filled=$(awk -v usage="$usage" -v total="$total" 'BEGIN {
        val = int((usage * total / 100) + 0.5);
        if (usage > 0 && val < 1) val = 1;
        print val;
    }')

    if [ "$filled" -gt "$total" ]; then filled=$total; fi
    if [ "$filled" -lt 0 ]; then filled=0; fi

    local empty=$((total - filled))

    printf "["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "]"
}

get_change_indicator() {
    local change=$1

    change=$(printf "%.1f" "$change")

    if (( $(echo "$change > 0" | bc -l) )); then
        echo "↑ +$change"
    elif (( $(echo "$change < 0" | bc -l) )); then
        echo "↓ $change"
    else
        echo "━ 0.0"
    fi
}

show_help() {
    echo ""
    echo "Linux System Monitor"
    echo ""
    echo "Usage:"
    echo " ./monitor.sh                 Show system snapshot"
    echo " ./monitor.sh --live          Start live monitoring"
    echo " ./monitor.sh --live 5        Refresh every 5 seconds"
    echo " ./monitor.sh --save          Save current snapshot"
    echo " ./monitor.sh --history       Show snapshot history"
    echo " ./monitor.sh --view          View latest snapshot"
    echo " ./monitor.sh --view FILE     View specific snapshot"
    echo " ./monitor.sh --compare       Compare latest snapshots"
    echo " ./monitor.sh --help          Show this help"
    echo ""
}

save_snapshot() {
    mkdir -p "$SNAPSHOT_DIR"

    local timestamp
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

    local filename="$SNAPSHOT_DIR/snapshot_${timestamp}.txt"

    show_dashboard > "$filename"

    echo "Snapshot saved: $filename"
}

show_history() {
    echo ""
    echo -e "${CYAN}┌──────────── SNAPSHOT HISTORY ─────────────┐${NC}"

    if [ ! -d "$SNAPSHOT_DIR" ] || [ -z "$(ls -A "$SNAPSHOT_DIR" 2>/dev/null)" ]; then
        echo "│ No snapshots found."
    else
        ls -1t "$SNAPSHOT_DIR" | nl -w2 -s'. '
    fi

    echo -e "${CYAN}└────────────────────────────────────────────┘${NC}"
}

view_snapshot() {
    local snapshot="$1"

    if [ "$snapshot" = "latest" ]; then
        snapshot=$(ls -1t "$SNAPSHOT_DIR" 2>/dev/null | head -n1)
    fi

    if [ -z "$snapshot" ]; then
        echo "No snapshots found."
        exit 1
    fi

    if [ ! -f "$SNAPSHOT_DIR/$snapshot" ]; then
        echo "Snapshot not found: $snapshot"
        exit 1
    fi

    echo ""
    echo -e "${CYAN}┌──────────── SNAPSHOT ────────────┐${NC}"
    cat "$SNAPSHOT_DIR/$snapshot"
    echo -e "${CYAN}└──────────────────────────────────┘${NC}"
}

extract_value() {
    local file="$1"
    local metric="$2"

    case "$metric" in
        CPU)
            sed -n 's/.*CPU  :.*\([0-9][0-9.]*\)%.*/\1/p' "$file" | head -n1
            ;;
        RAM)
            sed -n 's/.*RAM  :.*\([0-9][0-9.]*\)%.*/\1/p' "$file" | head -n1
            ;;
        DISK)
            sed -n 's/.*DISK :.*\([0-9][0-9.]*\)%.*/\1/p' "$file" | head -n1
            ;;
    esac
}

compare_snapshots() {
    local snapshots_list
    snapshots_list=$(ls -1t "$SNAPSHOT_DIR" 2>/dev/null | head -n2)

    local latest
    local previous

    latest=$(echo "$snapshots_list" | sed -n '1p')
    previous=$(echo "$snapshots_list" | sed -n '2p')

    if [ -z "$latest" ] || [ -z "$previous" ]; then
        echo "Need at least 2 snapshots to compare."
        exit 1
    fi

    local latest_cpu previous_cpu
    local latest_ram previous_ram
    local latest_disk previous_disk

    latest_cpu=$(extract_value "$SNAPSHOT_DIR/$latest" "CPU")
    previous_cpu=$(extract_value "$SNAPSHOT_DIR/$previous" "CPU")

    latest_ram=$(extract_value "$SNAPSHOT_DIR/$latest" "RAM")
    previous_ram=$(extract_value "$SNAPSHOT_DIR/$previous" "RAM")

    latest_disk=$(extract_value "$SNAPSHOT_DIR/$latest" "DISK")
    previous_disk=$(extract_value "$SNAPSHOT_DIR/$previous" "DISK")

    if [ -z "$latest_cpu" ] || [ -z "$previous_cpu" ] ||
       [ -z "$latest_ram" ] || [ -z "$previous_ram" ] ||
       [ -z "$latest_disk" ] || [ -z "$previous_disk" ]; then
        echo "Error: Could not read metric values from snapshots."
        exit 1
    fi

    local cpu_change ram_change disk_change

    cpu_change=$(echo "$latest_cpu - $previous_cpu" | bc)
    ram_change=$(echo "$latest_ram - $previous_ram" | bc)
    disk_change=$(echo "$latest_disk - $previous_disk" | bc)

    local CPU_CHANGE
    local RAM_CHANGE
    local DISK_CHANGE

    CPU_CHANGE=$(get_change_indicator "$cpu_change")
    RAM_CHANGE=$(get_change_indicator "$ram_change")
    DISK_CHANGE=$(get_change_indicator "$disk_change")

    echo ""
    echo -e "${CYAN}┌──────────── SNAPSHOT COMPARISON ─────────────┐${NC}"
    echo -e "${CYAN}│${NC}             OLD       CURRENT       CHANGE"
    echo -e "${CYAN}│${NC} CPU         ${previous_cpu}%       ${latest_cpu}%        ${CPU_CHANGE}"
    echo -e "${CYAN}│${NC} RAM         ${previous_ram}%      ${latest_ram}%       ${RAM_CHANGE}"
    echo -e "${CYAN}│${NC} DISK        ${previous_disk}%        ${latest_disk}%          ${DISK_CHANGE}"
    echo -e "${CYAN}└───────────────────────────────────────────────┘${NC}"
}

show_dashboard(){
	CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed 's/,/ /g' | awk '{for(i=1;i<=NF;i++) if ($i=="id") print 100-$(i-1)}')
	CPU_COLOR=$(get_color "$CPU_USAGE")
	CPU_STATUS=$(get_status "$CPU_USAGE")
	CPU_PROGRESS=$(progress_bar "$CPU_USAGE")
    CPU_ALERT=$(get_alert "CPU" "$CPU_USAGE")
	RAM_USAGE=$(free | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}')
	RAM_COLOR=$(get_color "$RAM_USAGE")
	RAM_STATUS=$(get_status "$RAM_USAGE")
	RAM_PROGRESS=$(progress_bar "$RAM_USAGE")
    RAM_ALERT=$(get_alert "RAM" "$RAM_USAGE")
	DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
	DISK_COLOR=$(get_color "$DISK_USAGE")
    DISK_STATUS=$(get_status "$DISK_USAGE")
	DISK_PROGRESS=$(progress_bar "$DISK_USAGE")
    DISK_ALERT=$(get_alert "DISK" "$DISK_USAGE")
    get_overall_status "$CPU_USAGE" "$RAM_USAGE" "$DISK_USAGE"
    OVERALL_STATUS=$?
	TOP_PROCESSES=$(ps -eo pid,%cpu,%mem,comm --sort=-%cpu | grep -v "monitor.sh" | head -6)
	echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
	echo -e "${CYAN}║          LINUX SYSTEM MONITOR              ║${NC}"
	echo -e "${CYAN}║             SYSTEM DASHBOARD               ║${NC}"
    echo -e "${CYAN}║     Snapshot: $(date '+%Y-%m-%d %H:%M:%S') UTC      ║${NC}"
	echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"


	echo ""
	echo -e "${CYAN}┌───────── SYSTEM INFORMATION ────────────────────┐${NC}"
	echo -e "${CYAN}│ Hostname:     ${GREEN}$(hostname)${NC}"
	echo -e "${CYAN}│ Current User: ${GREEN}$(whoami)${NC}"
	echo -e "${CYAN}│ Uptime:       ${GREEN}$(uptime -p)${NC}"
	echo -e "${CYAN}└─────────────────────────────────────────────────┘${NC}"


	echo ""
	echo -e "${CYAN}┌───────── RESOURCE USAGE ────────────────────────┐${NC}"
	echo -e "${CYAN}│ CPU  : ${CPU_PROGRESS} ${CPU_COLOR}${CPU_USAGE}%${NC}   [${CPU_STATUS}]"
	echo -e "${CYAN}│"
	echo -e "${CYAN}│ RAM  : ${RAM_PROGRESS} ${RAM_COLOR}${RAM_USAGE}%${NC}   [${RAM_STATUS}]"
	echo -e "${CYAN}│"
	echo -e "${CYAN}│ DISK : ${DISK_PROGRESS} ${DISK_COLOR}${DISK_USAGE}%${NC}   [${DISK_STATUS}]"
	echo -e "${CYAN}│"
	echo -e "${CYAN}└─────────────────────────────────────────────────┘${NC}"

	echo ""
	echo -e "${CYAN}┌──────────── TOP PROCESSES ──────────────┐${NC}"
	echo "$TOP_PROCESSES"
	echo -e "${CYAN}└─────────────────────────────────────────┘${NC}"

    echo ""

    if [ -n "$CPU_ALERT$RAM_ALERT$DISK_ALERT" ]; then
        echo -e "${CYAN}┌────────────── ALERTS ──────────────────┐${NC}"

        [ -n "$CPU_ALERT" ] && echo -e  "${CYAN}│${RED} ⚠ $CPU_ALERT${NC}"
        [ -n "$RAM_ALERT" ] && echo -e  "${CYAN}│${RED} ⚠ $RAM_ALERT${NC}"
        [ -n "$DISK_ALERT" ] && echo -e "${CYAN}│${RED} ⚠ $DISK_ALERT${NC}"

        echo -e "${CYAN}└─────────────────────────────────────────┘${NC}"
    else
        echo -e "${GREEN}✓ No active alerts${NC}"
    fi

    return "$OVERALL_STATUS"
}

if [ "$1" = "--live" ]; then

	INTERVAL=${2:-2}
	while true; do
		clear
		show_dashboard
		sleep "$INTERVAL"
	done

elif [ "$1" = "--help" ]; then
	show_help

elif [ "$1" = "--save" ]; then
	save_snapshot

elif [ "$1" = "--history" ]; then
	show_history

elif [ "$1" = "--view" ]; then
        view_snapshot "${2:-latest}"

elif [ "$1" = "--compare" ]; then
    compare_snapshots

else
	if [ -z "$1" ]; then
		show_dashboard
	else
		echo "Unknown option: $1"
		echo "Use './monitor.sh --help' for usage information."
		exit 1
	fi
fi



