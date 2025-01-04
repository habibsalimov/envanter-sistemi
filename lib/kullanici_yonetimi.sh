#!/bin/bash

kullanici_menu() {
    if [ "$KULLANICI_ROL" != "yonetici" ]; then
        zenity --error --text="Bu menüye erişim yetkiniz yok!"
        log_error "$AKTIF_KULLANICI" "Yetkisiz Erişim" "Kullanıcı yönetimi menüsüne erişim denemesi"
        return 1
    fi
    
    while true; do
        local secim=$(zenity --list \
            --title="Kullanıcı Yönetimi" \
            --text="İşlem seçin:" \
            --column="İşlem" \
            "Yeni Kullanıcı Ekle" \
            "Kullanıcı Listele" \
            "Kullanıcı Güncelle" \
            "Kullanıcı Sil" \
            "Şifre Sıfırla" \
            "Hesap Kilidini Kaldır" \
            "Ana Menüye Dön" \
            --width=300 --height=400)
        
        case $secim in
            "Yeni Kullanıcı Ekle") kullanici_ekle ;;
            "Kullanıcı Listele") kullanici_listele ;;
            "Kullanıcı Güncelle") kullanici_guncelle ;;
            "Kullanıcı Sil") kullanici_sil ;;
            "Şifre Sıfırla") sifre_sifirla ;;
            "Hesap Kilidini Kaldır") hesap_kilidi_kaldir ;;
            "Ana Menüye Dön"|"") break ;;
        esac
    done
}

kullanici_ekle() {
    local kullanici_bilgileri=$(zenity --forms --title="Yeni Kullanıcı" \
        --text="Kullanıcı Bilgileri" \
        --add-entry="Ad" \
        --add-entry="Soyad" \
        --add-combo="Rol" --combo-values="kullanici|yonetici" \
        --add-password="Parola" \
        --add-password="Parola (Tekrar)" \
        --separator="," 2>/dev/null)
    
    [ $? -ne 0 ] && return 1
    
    # Bilgileri ayır ve doğrula
    local ad=$(echo $kullanici_bilgileri | cut -d',' -f1)
    local soyad=$(echo $kullanici_bilgileri | cut -d',' -f2)
    local rol=$(echo $kullanici_bilgileri | cut -d',' -f3)
    local parola1=$(echo $kullanici_bilgileri | cut -d',' -f4)
    local parola2=$(echo $kullanici_bilgileri | cut -d',' -f5)
    
    # Validasyonlar
    [ -z "$ad" ] || [ -z "$soyad" ] || [ -z "$rol" ] || [ -z "$parola1" ] && {
        zenity --error --text="Tüm alanlar doldurulmalıdır!"; return 1;
    }
    
    [ "$parola1" != "$parola2" ] && {
        zenity --error --text="Parolalar eşleşmiyor!"; return 1;
    }
    
    [ ${#parola1} -lt 6 ] && {
        zenity --error --text="Parola en az 6 karakter olmalıdır!"; return 1;
    }
    
    # Kullanıcı adı oluştur ve kontrol et
    local kullanici_adi=$(echo "$ad.$soyad" | tr '[:upper:]' '[:lower:]' | tr 'ğüşıöçĞÜŞİÖÇ' 'gusiocGUSIOC')
    
    grep -q ",$kullanici_adi," kullanici.csv && {
        zenity --error --text="Bu kullanıcı adı zaten kullanımda!"; return 1;
    }
    
    # Kullanıcıyı ekle
    local kullanici_no=$(($(tail -n 1 kullanici.csv 2>/dev/null | cut -d',' -f1) + 1))
    local md5_parola=$(echo -n "$parola1" | md5sum | cut -d' ' -f1)
    
    progress_bar "Kullanıcı ekleniyor"
    echo "$kullanici_no,$ad,$soyad,$rol,$md5_parola,aktif" >> kullanici.csv
    
    zenity --info --text="Kullanıcı başarıyla eklendi!\n\nKullanıcı adı: $kullanici_adi\nRol: $rol"
}

kullanici_listele() {
    [ ! -s kullanici.csv ] && {
        zenity --info --text="Henüz kayıtlı kullanıcı bulunmamaktadır."; return 1;
    }
    
    local liste=$(awk -F',' '
        BEGIN {printf "%-5s %-20s %-15s %-15s %-10s %-10s\n", 
               "No", "Kullanıcı Adı", "Ad", "Soyad", "Rol", "Durum"}
        NR>1 {
            kullanici_adi=tolower($2 "." $3)
            gsub(/[ğüşıöç]/, "g", kullanici_adi)
            printf "%-5s %-20s %-15s %-15s %-10s %-10s\n", 
                   $1, kullanici_adi, $2, $3, $4, $6
        }' kullanici.csv)
    
    zenity --text-info --title="Kullanıcı Listesi" \
        --width=700 --height=400 --font="monospace" \
        --filename=<(echo "$liste")
}

sifre_sifirla() {
    local kullanici_listesi=$(awk -F',' 'NR>1 {print $1 "|" $2 "." $3}' kullanici.csv)
    
    local secilen=$(zenity --list \
        --title="Şifre Sıfırla" \
        --text="Şifresi sıfırlanacak kullanıcıyı seçin:" \
        --column="No" --column="Kullanıcı Adı" \
        $(echo "$kullanici_listesi" | tr '|' ' ') \
        --width=300 --height=400)
    
    [ -z "$secilen" ] && return 1
    
    local yeni_sifre=$(zenity --password --title="Yeni Şifre" --text="Yeni şifreyi girin:")
    [ -z "$yeni_sifre" ] && return 1
    
    local sifre_tekrar=$(zenity --password --title="Şifre Doğrulama" --text="Yeni şifreyi tekrar girin:")
    
    [ "$yeni_sifre" != "$sifre_tekrar" ] && {
        zenity --error --text="Şifreler eşleşmiyor!"; return 1;
    }
    
    [ ${#yeni_sifre} -lt 6 ] && {
        zenity --error --text="Şifre en az 6 karakter olmalıdır!"; return 1;
    }
    
    progress_bar "Şifre sıfırlanıyor"
    local md5_sifre=$(echo -n "$yeni_sifre" | md5sum | cut -d' ' -f1)
    sed -i "s/\(^$secilen,[^,]*,[^,]*,[^,]*,\)[^,]*,/\1$md5_sifre,/" kullanici.csv
    
    zenity --info --text="Şifre başarıyla sıfırlandı!"
}

hesap_kilidi_kaldir() {
    local kilitli_hesaplar=$(awk -F',' '$6=="kilitli" {print $1 "|" $2 "." $3}' kullanici.csv)
    
    [ -z "$kilitli_hesaplar" ] && {
        zenity --info --text="Kilitli hesap bulunmamaktadır."; return 0;
    }
    
    local secilen=$(zenity --list \
        --title="Hesap Kilidi Kaldır" \
        --text="Kilidi kaldırılacak hesabı seçin:" \
        --column="No" --column="Kullanıcı Adı" \
        $(echo "$kilitli_hesaplar" | tr '|' ' ') \
        --width=300 --height=400)
    
    [ -z "$secilen" ] && return 1
    
    progress_bar "Hesap kilidi kaldırılıyor"
    sed -i "s/\(^$secilen,[^,]*,[^,]*,[^,]*,[^,]*,\)kilitli/\1aktif/" kullanici.csv
    
    zenity --info --text="Hesap kilidi başarıyla kaldırıldı!"
}

# ...additional user management functions here...
