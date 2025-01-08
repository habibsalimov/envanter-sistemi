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
            "Ana Menüye Dön" \
            --width=300 --height=400)
        
        case $secim in
            "Yeni Kullanıcı Ekle") kullanici_ekle ;;
            "Kullanıcı Listele") kullanici_listele ;;
            "Kullanıcı Güncelle") kullanici_guncelle ;;
            "Kullanıcı Sil") kullanici_sil ;;
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
    [ ! -s "$KULLANICI_DOSYASI" ] && {
        zenity --info --text="Henüz kayıtlı kullanıcı bulunmamaktadır."; return 1;
    }
    
    local liste=$(awk -F',' '
        BEGIN {printf "%-5s %-20s %-15s %-15s %-10s %-10s\n", 
               "No", "Kullanıcı Adı", "Ad", "Soyad", "Rol", "Durum"}
        {
            kullanici_adi=tolower($2 "." $3)
            gsub(/[ğüşıöç]/, "g", kullanici_adi)
            printf "%-5s %-20s %-15s %-15s %-10s %-10s\n", 
                   $1, kullanici_adi, $2, $3, $4, $6
        }' "$KULLANICI_DOSYASI")
    
    zenity --text-info --title="Kullanıcı Listesi" \
        --width=700 --height=400 --font="monospace" \
        --filename=<(echo "$liste")
}

kullanici_guncelle() {
    local kullanici_listesi=$(awk -F',' 'NR>1 {
        kullanici_adi=tolower($2 "." $3)
        gsub(/[ğüşıöç]/, "g", kullanici_adi)
        print $1 "|" kullanici_adi "|" $4
    }' kullanici.csv)
    
    [ -z "$kullanici_listesi" ] && {
        zenity --error --text="Güncellenecek kullanıcı bulunamadı!"; return 1;
    }
    
    local secilen=$(zenity --list \
        --title="Kullanıcı Güncelle" \
        --text="Güncellenecek kullanıcıyı seçin:" \
        --column="No" --column="Kullanıcı Adı" --column="Rol" \
        $(echo "$kullanici_listesi" | tr '|' ' ') \
        --width=400 --height=300)
    
    [ -z "$secilen" ] && return 1
    
    # Mevcut bilgileri al
    local mevcut_bilgiler=$(grep "^$secilen," kullanici.csv)
    local mevcut_ad=$(echo $mevcut_bilgiler | cut -d',' -f2)
    local mevcut_soyad=$(echo $mevcut_bilgiler | cut -d',' -f3)
    local mevcut_rol=$(echo $mevcut_bilgiler | cut -d',' -f4)
    local mevcut_durum=$(echo $mevcut_bilgiler | cut -d',' -f6)
    
    local yeni_bilgiler=$(zenity --forms --title="Kullanıcı Güncelle" \
        --text="Kullanıcı Bilgilerini Güncelleyin" \
        --add-entry="Ad [$mevcut_ad]" \
        --add-entry="Soyad [$mevcut_soyad]" \
        --add-combo="Rol [$mevcut_rol]" --combo-values="kullanici|yonetici" \
        --add-combo="Durum [$mevcut_durum]" --combo-values="aktif|kilitli" \
        --add-password="Yeni Parola (Boş bırakılabilir)" \
        --add-password="Parola Tekrar" \
        --separator="," 2>/dev/null)
    
    [ $? -ne 0 ] && return 1
    
    # Yeni bilgileri ayır
    local yeni_ad=$(echo $yeni_bilgiler | cut -d',' -f1)
    local yeni_soyad=$(echo $yeni_bilgiler | cut -d',' -f2)
    local yeni_rol=$(echo $yeni_bilgiler | cut -d',' -f3)
    local yeni_durum=$(echo $yeni_bilgiler | cut -d',' -f4)
    local yeni_parola1=$(echo $yeni_bilgiler | cut -d',' -f5)
    local yeni_parola2=$(echo $yeni_bilgiler | cut -d',' -f6)
    
    # Boş alanları mevcut değerlerle doldur
    [ -z "$yeni_ad" ] && yeni_ad=$mevcut_ad
    [ -z "$yeni_soyad" ] && yeni_soyad=$mevcut_soyad
    [ -z "$yeni_rol" ] && yeni_rol=$mevcut_rol
    [ -z "$yeni_durum" ] && yeni_durum=$mevcut_durum
    
    # Parola kontrolü
    if [ -n "$yeni_parola1" ]; then
        [ "$yeni_parola1" != "$yeni_parola2" ] && {
            zenity --error --text="Parolalar eşleşmiyor!"; return 1;
        }
        [ ${#yeni_parola1} -lt 6 ] && {
            zenity --error --text="Parola en az 6 karakter olmalıdır!"; return 1;
        }
        local md5_parola=$(echo -n "$yeni_parola1" | md5sum | cut -d' ' -f1)
    else
        local md5_parola=$(echo $mevcut_bilgiler | cut -d',' -f5)
    fi
    
    # Onay al
    zenity --question \
        --title="Güncelleme Onayı" \
        --text="Aşağıdaki değişiklikleri onaylıyor musunuz?\n\nAd: $mevcut_ad -> $yeni_ad\nSoyad: $mevcut_soyad -> $yeni_soyad\nRol: $mevcut_rol -> $yeni_rol\nDurum: $mevcut_durum -> $yeni_durum" \
        --ok-label="Evet" --cancel-label="Hayır" || return 1
    
    # Güncelle
    progress_bar "Kullanıcı güncelleniyor"
    sed -i "s/^$secilen,.*/$secilen,$yeni_ad,$yeni_soyad,$yeni_rol,$md5_parola,$yeni_durum/" kullanici.csv
    
    zenity --info --text="Kullanıcı başarıyla güncellendi!"
}

kullanici_sil() {
    local kullanici_listesi=$(awk -F',' 'NR>1 {
        kullanici_adi=tolower($2 "." $3)
        gsub(/[ğüşıöç]/, "g", kullanici_adi)
        print $1 "|" kullanici_adi "|" $4 "|" $6
    }' kullanici.csv)
    
    [ -z "$kullanici_listesi" ] && {
        zenity --error --text="Silinecek kullanıcı bulunamadı!"; return 1;
    }
    
    local secilen=$(zenity --list \
        --title="Kullanıcı Sil" \
        --text="Silmek istediğiniz kullanıcıyı seçin:" \
        --column="No" --column="Kullanıcı Adı" --column="Rol" --column="Durum" \
        $(echo "$kullanici_listesi" | tr '|' ' ') \
        --width=400 --height=300)
    
    [ -z "$secilen" ] && return 1
    
    # Yönetici kontrolü
    local yonetici_sayisi=$(grep -c ",yonetici," kullanici.csv)
    local silinecek_rol=$(grep "^$secilen," kullanici.csv | cut -d',' -f4)
    
    if [ "$silinecek_rol" = "yonetici" ] && [ $yonetici_sayisi -le 1 ]; then
        zenity --error --text="Son yönetici kullanıcısını silemezsiniz!"
        return 1
    fi
    
    # Aktif kullanıcı kontrolü
    local silinecek_kullanici=$(grep "^$secilen," kullanici.csv | cut -d',' -f2,3)
    local aktif_kullanici_tam=$(echo "$AKTIF_KULLANICI" | tr '.' ' ')
    
    if [ "$silinecek_kullanici" = "$aktif_kullanici_tam" ]; then
        zenity --error --text="Aktif kullanıcıyı silemezsiniz!"
        return 1
    fi
    
    # Onay al
    zenity --question \
        --title="Silme Onayı" \
        --text="Bu kullanıcıyı silmek istediğinizden emin misiniz?\nBu işlem geri alınamaz!" \
        --ok-label="Evet" --cancel-label="Hayır" || return 1
    
    # Sil
    progress_bar "Kullanıcı siliniyor"
    sed -i "/^$secilen,/d" kullanici.csv
    
    zenity --info --text="Kullanıcı başarıyla silindi!"
}

# ...additional user management functions here...
