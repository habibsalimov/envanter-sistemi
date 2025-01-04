#!/bin/bash

login() {
    local giris_hakki=$MAX_GIRIS_HAKKI
    
    while [ $giris_hakki -gt 0 ]; do
        local giris=$(zenity --forms --title="Sistem Girişi" \
            --text="Kullanıcı Girişi\nKalan deneme hakkı: $giris_hakki" \
            --add-entry="Kullanıcı Adı" \
            --add-password="Parola" \
            --separator="," 2>/dev/null)
        
        [ $? -ne 0 ] && exit 0
        
        local kullanici_adi=$(echo $giris | cut -d',' -f1)
        local parola=$(echo $giris | cut -d',' -f2)
        local md5_parola=$(echo -n "$parola" | md5sum | cut -d' ' -f1)
        
        if grep -q ",$kullanici_adi,.*,$md5_parola,aktif" kullanici.csv; then
            AKTIF_KULLANICI=$kullanici_adi
            KULLANICI_ROL=$(grep ",$kullanici_adi," kullanici.csv | cut -d',' -f4)
            progress_bar "Giriş yapılıyor"
            return 0
        else
            ((giris_hakki--))
            if [ $giris_hakki -eq 0 ]; then
                zenity --error --title="Hata" \
                    --text="Giriş hakkınız kalmadı!\nHesabınız güvenlik nedeniyle kilitlenmiştir."
                sed -i "s/,aktif/,kilitli/" kullanici.csv
                log_error "Sistem" "Hesap Kilitleme" "$kullanici_adi kullanıcısı için hesap kilitlendi"
                exit 1
            fi
            zenity --error --title="Hata" \
                --text="Hatalı kullanıcı adı veya parola!\nKalan deneme hakkı: $giris_hakki"
        fi
    done
}
