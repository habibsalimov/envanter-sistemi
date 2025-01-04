#!/bin/bash

login() {
    # Kullanıcı yoksa ilk kullanıcı oluşturma
    if [ ! -s kullanici.csv ] || [ $(wc -l < kullanici.csv) -le 1 ]; then
        zenity --info --title="İlk Kullanıcı" \
            --text="Sistemde kayıtlı kullanıcı bulunmamaktadır.\nİlk yönetici kullanıcısını oluşturmanız gerekmektedir."
        ilk_kullanici_olustur
        return $?
    fi

    local giris_hakki=$MAX_GIRIS_HAKKI
    
    while [ $giris_hakki -gt 0 ]; do
        local giris=$(zenity --forms --title="Sistem Girişi" \
            --text="Kullanıcı Girişi\nKalan deneme hakkı: $giris_hakki" \
            --add-entry="Kullanıcı Adı" \
            --add-password="Parola" \
            --separator="," \
            --extra-button="Yeni Kullanıcı" 2>/dev/null)
        
        local button=$?
        
        # Çıkış butonu kontrolü
        [ $button -eq 1 ] && exit 1
        
        # Yeni Kullanıcı butonu kontrolü
        if [ $button -eq 2 ]; then
            yeni_kullanici_olustur
            continue
        fi
        
        # Kullanıcı bilgilerini ayır
        local kullanici_adi=$(echo "$giris" | cut -d',' -f1)
        local parola=$(echo "$giris" | cut -d',' -f2)
        
        # Boş giriş kontrolü
        [ -z "$kullanici_adi" ] || [ -z "$parola" ] && {
            zenity --error --title="Hata" --text="Kullanıcı adı ve parola boş bırakılamaz!"
            continue
        }
        
        local md5_parola=$(echo -n "$parola" | md5sum | cut -d' ' -f1)
        local kullanici_satiri=$(grep -i ",$kullanici_adi," kullanici.csv)
        
        if [ -n "$kullanici_satiri" ] && echo "$kullanici_satiri" | grep -q ",$md5_parola,aktif"; then
            AKTIF_KULLANICI=$kullanici_adi
            KULLANICI_ROL=$(echo "$kullanici_satiri" | cut -d',' -f4)
            progress_bar "Giriş yapılıyor"
            return 0
        else
            ((giris_hakki--))
            if [ $giris_hakki -eq 0 ]; then
                zenity --error --title="Hata" \
                    --text="Giriş hakkınız kalmadı!\nHesabınız güvenlik nedeniyle kilitlenmiştir."
                [ -n "$kullanici_satiri" ] && sed -i "s/,aktif/,kilitli/" kullanici.csv
                log_error "Sistem" "Hesap Kilitleme" "$kullanici_adi kullanıcısı için hesap kilitlendi"
                return 1
            fi
            zenity --error --title="Hata" \
                --text="Hatalı kullanıcı adı veya parola!\nKalan deneme hakkı: $giris_hakki"
        fi
    done
    return 1
}

ilk_kullanici_olustur() {
    local kullanici_bilgileri=$(zenity --forms --title="İlk Yönetici Oluştur" \
        --text="Yönetici Kullanıcı Bilgileri" \
        --add-entry="Ad" \
        --add-entry="Soyad" \
        --add-password="Parola" \
        --add-password="Parola (Tekrar)" \
        --separator="," 2>/dev/null)
    
    [ $? -ne 0 ] && return 1
    
    local ad=$(echo $kullanici_bilgileri | cut -d',' -f1)
    local soyad=$(echo $kullanici_bilgileri | cut -d',' -f2)
    local parola1=$(echo $kullanici_bilgileri | cut -d',' -f3)
    local parola2=$(echo $kullanici_bilgileri | cut -d',' -f4)
    
    # Validasyonlar
    [ -z "$ad" ] || [ -z "$soyad" ] || [ -z "$parola1" ] && {
        zenity --error --text="Tüm alanlar doldurulmalıdır!"; 
        return 1;
    }
    
    [ "$parola1" != "$parola2" ] && {
        zenity --error --text="Parolalar eşleşmiyor!"; 
        return 1;
    }
    
    [ ${#parola1} -lt 6 ] && {
        zenity --error --text="Parola en az 6 karakter olmalıdır!"; 
        return 1;
    }
    
    # Kullanıcı oluştur
    echo "$KULLANICI_BASLIK" > kullanici.csv
    local md5_parola=$(echo -n "$parola1" | md5sum | cut -d' ' -f1)
    echo "1,$ad,$soyad,yonetici,$md5_parola,aktif" >> kullanici.csv
    
    zenity --info --text="İlk yönetici kullanıcısı oluşturuldu!\n\nKullanıcı adı: $ad.$soyad"
    return 0
}

yeni_kullanici_olustur() {
    local kullanici_bilgileri=$(zenity --forms --title="Yeni Kullanıcı" \
        --text="Kullanıcı Bilgileri" \
        --add-entry="Ad" \
        --add-entry="Soyad" \
        --add-password="Parola" \
        --add-password="Parola (Tekrar)" \
        --separator="," 2>/dev/null)
    
    [ $? -ne 0 ] && return 1
    
    local ad=$(echo $kullanici_bilgileri | cut -d',' -f1)
    local soyad=$(echo $kullanici_bilgileri | cut -d',' -f2)
    local parola1=$(echo $kullanici_bilgileri | cut -d',' -f3)
    local parola2=$(echo $kullanici_bilgileri | cut -d',' -f4)
    
    # Validasyonlar
    [ -z "$ad" ] || [ -z "$soyad" ] || [ -z "$parola1" ] && {
        zenity --error --text="Tüm alanlar doldurulmalıdır!"; 
        return 1;
    }
    
    [ "$parola1" != "$parola2" ] && {
        zenity --error --text="Parolalar eşleşmiyor!"; 
        return 1;
    }
    
    [ ${#parola1} -lt 6 ] && {
        zenity --error --text="Parola en az 6 karakter olmalıdır!"; 
        return 1;
    }
    
    # Kullanıcı adı oluştur ve kontrol et
    local kullanici_adi=$(echo "$ad.$soyad" | tr '[:upper:]' '[:lower:]' | tr 'ğüşıöçĞÜŞİÖÇ' 'gusiocGUSIOC')
    
    grep -q ",$kullanici_adi," kullanici.csv && {
        zenity --error --text="Bu kullanıcı adı zaten kullanımda!"; 
        return 1;
    }
    
    # Kullanıcıyı ekle
    local kullanici_no=$(($(tail -n 1 kullanici.csv 2>/dev/null | cut -d',' -f1) + 1))
    local md5_parola=$(echo -n "$parola1" | md5sum | cut -d' ' -f1)
    
    echo "$kullanici_no,$ad,$soyad,kullanici,$md5_parola,aktif" >> kullanici.csv
    
    zenity --info --text="Kullanıcı başarıyla oluşturuldu!\n\nKullanıcı adı: $kullanici_adi"
    return 0
}
