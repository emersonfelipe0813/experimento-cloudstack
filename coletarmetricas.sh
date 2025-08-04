#!/bin/bash

export LANG=C
LOG_FILE="metricas_sistema.csv"

# Cabeçalho CSV
if [ ! -f "$LOG_FILE" ]; then
    echo "DataHora,CPU_uso(%),CPU_ocioso(%),RAM_total(MB),RAM_usada(MB),RAM_livre(MB),RAM_cache(MB),Disco_total(GB),Disco_usado(GB),Disco_livre(GB)" > "$LOG_FILE"
fi

while true; do
    DATAHORA=$(date +"%Y-%m-%d %H:%M:%S")

    # CPU
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk -F'id' '{print $(NF-1)}' | awk '{print $NF}')
    if [[ -z "$CPU_IDLE" || ! "$CPU_IDLE" =~ ^[0-9.]+$ ]]; then
        CPU_IDLE=0
    fi
    CPU_USO=$(awk "BEGIN {printf \"%.2f\", 100 - $CPU_IDLE}")

    # RAM
    read -r _ RAM_TOTAL RAM_USADA RAM_LIVRE _ _ _ RAM_CACHE <<< "$(free -m | awk '/^Mem:/ {print $2, $3, $4, $7}')"

    # DISCO - Em GB reais sem letras
    DISK_STATS=$(df -B1G / | awk 'NR==2 {print $2, $3, $4}')
    read -r DISK_TOTAL_BYTES DISK_USADO_BYTES DISK_LIVRE_BYTES <<< "$DISK_STATS"
    DISK_TOTAL=$(echo "$DISK_TOTAL_BYTES" | awk '{print int($1)}')
    DISK_USADO=$(echo "$DISK_USADO_BYTES" | awk '{print int($1)}')
    DISK_LIVRE=$(echo "$DISK_LIVRE_BYTES" | awk '{print int($1)}')

    # Linha final do CSV
    echo "$DATAHORA,$CPU_USO,$CPU_IDLE,$RAM_TOTAL,$RAM_USADA,$RAM_LIVRE,$RAM_CACHE,$DISK_TOTAL,$DISK_USADO,$DISK_LIVRE" >> "$LOG_FILE"

    sleep 10
done
