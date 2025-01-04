#!/bin/bash

setup_files() {
    # CSV dosyalarını oluştur
    [ ! -f "depo.csv" ] && {
        echo "$DEPO_BASLIK" > depo.csv
        # Örnek ürün eklerken tüm alanların doğru formatta olduğundan emin ol
        echo "1,Örnek-Ürün,100,10.50,Genel" >> depo.csv
    }
    
    [ ! -f "kullanici.csv" ] && {
        echo "$KULLANICI_BASLIK" > kullanici.csv
    }
    
    [ ! -f "log.csv" ] && {
        echo "$LOG_BASLIK" > log.csv
    }
    
    # Dizinleri oluştur
    mkdir -p yedekler
    
    # Dosya izinlerini ayarla
    chmod 644 *.csv
    chmod 755 yedekler
}

check_debug() {
    if [ "$1" = "--debug" ]; then
        set -x
        LOG_LEVEL="DEBUG"
        echo "Debug modu aktif"
    fi
}
