#!/bin/bash

log_error() {
    local zaman=$(date '+%Y-%m-%d %H:%M:%S')
    local kullanici=$1
    local islem=$2
    local detay=$3
    local hata_no=$(wc -l < log.csv)
    
    echo "$hata_no,$zaman,$kullanici,$islem,$detay" >> log.csv
}

show_logs() {
    if [ -s log.csv ]; then
        local log_icerik=$(awk -F',' '
            BEGIN {printf "%-8s %-20s %-15s %-20s %-30s\n",
                   "Hata No", "Zaman", "Kullanıcı", "İşlem", "Detay"}
            {printf "%-8s %-20s %-15s %-20s %-30s\n",
                   $1, $2, $3, $4, $5}' log.csv)
        
        zenity --text-info \
            --title="Hata Kayıtları" \
            --width=800 \
            --height=400 \
            --font="monospace" \
            --filename=<(echo "$log_icerik")
    else
        zenity --info \
            --title="Bilgi" \
            --text="Henüz hata kaydı bulunmamaktadır."
    fi
}
