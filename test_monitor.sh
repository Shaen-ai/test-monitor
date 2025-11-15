#!/bin/bash

PROCESS="test"
URL="https://test.com/monitoring/test/api"
LOG="/var/log/monitoring.log"

STATE_DIR="/var/lib/test-monitor"
STATE_FILE="$STATE_DIR/last_start"

# Готовим каталог для хранения состояния
mkdir -p "$STATE_DIR"

# 1. Проверяем, запущен ли процесс
PID=$(pgrep -xo "$PROCESS") || exit 0  # процесса нет — тихо выходим

# 2. Узнаём время старта процесса по /proc/<pid>
if [[ ! -d "/proc/$PID" ]]; then
    exit 0
fi

CUR_START=$(stat -c %Y "/proc/$PID" 2>/dev/null || echo 0)

LAST_START=0
if [[ -f "$STATE_FILE" ]]; then
    LAST_START=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
fi

# 3. Если процесс перезапустился — пишем в лог
if [[ "$CUR_START" != "$LAST_START" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') process ${PROCESS} restarted (pid=${PID})" >> "$LOG"
    echo "$CUR_START" > "$STATE_FILE"
fi

# 4. Стучимся на мониторинг
if ! curl -fsS --max-time 5 "$URL" >/dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') monitoring server unavailable (${URL})" >> "$LOG"
fi