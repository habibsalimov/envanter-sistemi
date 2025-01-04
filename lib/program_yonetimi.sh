#!/bin/bash

program_menu() {
    while true; do
        local secim=$(zenity --list \
            --title="Program Yönetimi" \
            --text="İşlem seçin:" \
            --column="İşlem" \
            "Disk Kullanımını Göster" \
            "Yedekleme Yap" \
            "Hata Kayıtlarını Göster" \
            "Sistem Durumu" \
            "Ana Menüye Dön" \
            --width=300 --height=400)
        
        case $secim in
            "Disk Kullanımını Göster") disk_kullanimi_goster ;;
            "Yedekleme Yap") yedekleme_yap ;;
            "Hata Kayıtlarını Göster") show_logs ;;
            "Sistem Durumu") sistem_durumu ;;
            "Ana Menüye Dön"|"") break ;;
        esac
    done
}

disk_kullanimi_goster() {
    local disk_bilgisi=$(df -h . | awk 'NR==2 {print "Toplam Alan: " $2 "\nKullanılan: " $3 "\nBoş Alan: " $4 "\nKullanım Oranı: " $5}')
    local dosya_boyutlari=$(du -sh *.csv | awk '{printf "%s: %s\n", $2, $1}')
    
    zenity --info --title="Disk Kullanımı" \
        --text="Disk Bilgileri:\n\n$disk_bilgisi\n\nDosya Boyutları:\n$dosya_boyutlari"
}

yedekleme_yap() {
    [ ! -d "yedekler" ] && mkdir -p yedekler
    
    local tarih=$(date +%Y%m%d_%H%M%S)
    local yedek_dizin="yedekler/yedek_$tarih"
    
    (
    echo "10" ; sleep 0.2
    echo "# Yedekleme dizini oluşturuluyor..." ; sleep 0.2
    mkdir -p "$yedek_dizin"
    
    echo "30" ; sleep 0.2
    echo "# Veritabanı dosyaları yedekleniyor..." ; sleep 0.2
    cp depo.csv kullanici.csv "$yedek_dizin/"
    
    echo "60" ; sleep 0.2
    echo "# Log dosyaları yedekleniyor..." ; sleep 0.2
    cp log.csv "$yedek_dizin/"
    
    echo "100" ; sleep 0.2
    ) | zenity --progress \
        --title="Yedekleme" \
        --text="Yedekleme başlatılıyor..." \
        --percentage=0 \
        --auto-close
    
    [ $? = 0 ] && zenity --info --title="Başarılı" --text="Yedekleme başarıyla tamamlandı!\nYedek konumu: $yedek_dizin" \
                || zenity --error --title="Hata" --text="Yedekleme sırasında bir hata oluştu!"
}

sistem_durumu() {
    local urun_sayisi=$(wc -l < depo.csv)
    local kullanici_sayisi=$(wc -l < kullanici.csv)
    local log_sayisi=$(wc -l < log.csv)
    local son_yedek=$(ls -t yedekler/ 2>/dev/null | head -n1)
    
    local durum="Sistem Durumu:\n\n"
    durum+="Toplam Ürün Sayısı: $((urun_sayisi-1))\n"
    durum+="Toplam Kullanıcı Sayısı: $((kullanici_sayisi-1))\n"
    durum+="Toplam Log Kaydı: $((log_sayisi-1))\n"
    durum+="\n${son_yedek:+Son Yedekleme: $son_yedek}"
    durum+="${son_yedek:-Henüz yedekleme yapılmamış!}"
    
    zenity --info --title="Sistem Durumu" --text="$durum" --width=400
}
