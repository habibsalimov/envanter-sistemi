#!/bin/bash

# Ürün ekleme fonksiyonu
urun_ekle() {
    if [ "$KULLANICI_ROL" != "yonetici" ]; then
        zenity --error --text="Bu işlem için yönetici yetkisine sahip olmalısınız!"
        log_error "$AKTIF_KULLANICI" "Yetkisiz Erişim" "Ürün ekleme denemesi"
        return 1
    fi
    
    local urun_bilgileri=$(zenity --forms --title="Ürün Ekle" \
        --text="Yeni Ürün Bilgileri" \
        --add-entry="Ürün Adı" \
        --add-entry="Stok Miktarı" \
        --add-entry="Birim Fiyat (TL)" \
        --add-entry="Kategori" \
        --separator="," 2>/dev/null)
    
    [ $? -ne 0 ] && return 1
    
    # Bilgileri ayır ve doğrula
    local urun_adi=$(echo $urun_bilgileri | cut -d',' -f1)
    local stok_miktari=$(echo $urun_bilgileri | cut -d',' -f2)
    local birim_fiyat=$(echo $urun_bilgileri | cut -d',' -f3)
    local kategori=$(echo $urun_bilgileri | cut -d',' -f4)
    
    # Doğrulama kontrolleri
    if [[ "$urun_adi" =~ [[:space:]] ]] || [[ "$kategori" =~ [[:space:]] ]]; then
        zenity --error --text="Ürün adı ve kategori boşluk içeremez!"
        return 1
    fi
    
    if ! [[ "$stok_miktari" =~ ^[0-9]+$ ]] || ! [[ "$birim_fiyat" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        zenity --error --text="Geçersiz stok miktarı veya birim fiyat!"
        return 1
    fi
    
    # Mükerrer kontrol
    if grep -q ",$urun_adi," depo.csv; then
        zenity --error --text="Bu ürün adı zaten mevcut!"
        log_error "$AKTIF_KULLANICI" "Ürün Ekleme Hatası" "Mükerrer: $urun_adi"
        return 1
    fi
    
    # Yeni ürün numarası ve kayıt
    local urun_no=$(($(tail -n 1 depo.csv 2>/dev/null | cut -d',' -f1) + 1))
    progress_bar "Ürün ekleniyor"
    echo "$urun_no,$urun_adi,$stok_miktari,$birim_fiyat,$kategori" >> depo.csv
    
    zenity --info --text="Ürün başarıyla eklendi!"
}

# Ürün listeleme fonksiyonu
urun_listele() {
    # Debug için dosya içeriğini kontrol et
    if [ ! -f "depo.csv" ]; then
        zenity --error --text="Depo dosyası bulunamadı!"
        return 1
    fi

    # Dosya içeriğini göster
    if [ ! -s depo.csv ]; then
        zenity --info --text="Henüz kayıtlı ürün bulunmamaktadır."
        return 1
    fi
    
    # Dosya içeriğini formatlayarak göster
    local liste=$(awk -F',' '
        BEGIN {
            printf "%-8s %-20s %-12s %-12s %-15s\n", "No", "Ürün Adı", "Stok", "Fiyat (TL)", "Kategori"
            printf "%-8s %-20s %-12s %-12s %-15s\n", "--------", "--------------------", "------------", "------------", "---------------"
        }
        NR>1 {
            printf "%-8s %-20s %-12s %-12.2f %-15s\n", $1, $2, $3, $4, $5
        }' depo.csv)
    
    if [ -z "$liste" ]; then
        zenity --error --text="Ürün listesi oluşturulurken bir hata oluştu!"
        return 1
    fi

    zenity --text-info \
        --title="Ürün Listesi" \
        --width=800 \
        --height=400 \
        --font="monospace" \
        --filename=<(echo "$liste")
}

# Ürün güncelleme fonksiyonu
urun_guncelle() {
    if [ "$KULLANICI_ROL" != "yonetici" ]; then
        zenity --error --text="Bu işlem için yönetici yetkisine sahip olmalısınız!"
        log_error "$AKTIF_KULLANICI" "Yetkisiz Erişim" "Ürün güncelleme denemesi"
        return 1
    fi
    
    local urun_listesi=$(awk -F',' 'NR>1 {print $1 "|" $2}' depo.csv)
    local secilen_urun=$(zenity --list --title="Ürün Güncelle" \
        --text="Güncellenecek ürünü seçin:" \
        --column="No" --column="Ürün Adı" \
        $(echo "$urun_listesi" | tr '|' ' ') \
        --width=400 --height=300)
    
    [ -z "$secilen_urun" ] && return 1
    
    # Seçilen ürünün mevcut bilgilerini al
    local mevcut_bilgiler=$(grep "^$secilen_urun," depo.csv)
    local mevcut_ad=$(echo $mevcut_bilgiler | cut -d',' -f2)
    local mevcut_stok=$(echo $mevcut_bilgiler | cut -d',' -f3)
    local mevcut_fiyat=$(echo $mevcut_bilgiler | cut -d',' -f4)
    local mevcut_kategori=$(echo $mevcut_bilgiler | cut -d',' -f5)
    
    # Güncelleme formunu göster
    local yeni_bilgiler=$(zenity --forms --title="Ürün Güncelle" \
        --text="Ürün Bilgilerini Güncelleyin\n\nMevcut Bilgiler:\nÜrün Adı: $mevcut_ad\nStok: $mevcut_stok\nFiyat: $mevcut_fiyat TL\nKategori: $mevcut_kategori\n" \
        --add-entry="Yeni Ürün Adı" \
        --add-entry="Yeni Stok Miktarı" \
        --add-entry="Yeni Birim Fiyat (TL)" \
        --add-entry="Yeni Kategori" \
        --separator="," 2>/dev/null)
    
    [ $? -ne 0 ] && return 1
    
    # Yeni bilgileri ayır
    local yeni_ad=$(echo $yeni_bilgiler | cut -d',' -f1)
    local yeni_stok=$(echo $yeni_bilgiler | cut -d',' -f2)
    local yeni_fiyat=$(echo $yeni_bilgiler | cut -d',' -f3)
    local yeni_kategori=$(echo $yeni_bilgiler | cut -d',' -f4)
    
    # Boş alanları mevcut değerlerle doldur
    [ -z "$yeni_ad" ] && yeni_ad=$mevcut_ad
    [ -z "$yeni_stok" ] && yeni_stok=$mevcut_stok
    [ -z "$yeni_fiyat" ] && yeni_fiyat=$mevcut_fiyat
    [ -z "$yeni_kategori" ] && yeni_kategori=$mevcut_kategori
    
    # Validasyonlar
    if [[ "$yeni_ad" =~ [[:space:]] ]] || [[ "$yeni_kategori" =~ [[:space:]] ]]; then
        zenity --error --text="Ürün adı ve kategori boşluk içeremez!"
        return 1
    fi
    
    if ! [[ "$yeni_stok" =~ ^[0-9]+$ ]] || ! [[ "$yeni_fiyat" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        zenity --error --text="Geçersiz stok miktarı veya birim fiyat!"
        return 1
    fi
    
    # Mükerrer kontrol (kendi kaydı hariç)
    if [ "$yeni_ad" != "$mevcut_ad" ] && grep -q ",$yeni_ad," depo.csv; then
        zenity --error --text="Bu ürün adı zaten mevcut!"
        return 1
    fi
    
    # Değişiklik onayı
    zenity --question \
        --title="Güncelleme Onayı" \
        --text="Aşağıdaki değişiklikleri onaylıyor musunuz?\n\nÜrün Adı: $mevcut_ad -> $yeni_ad\nStok: $mevcut_stok -> $yeni_stok\nFiyat: $mevcut_fiyat -> $yeni_fiyat\nKategori: $mevcut_kategori -> $yeni_kategori" \
        --ok-label="Evet" \
        --cancel-label="Hayır" || return 1
    
    # Yedek al ve güncelle
    progress_bar "Ürün güncelleniyor"
    cp depo.csv yedekler/depo_$(date +%Y%m%d_%H%M%S).csv
    sed -i "s/^$secilen_urun,.*/$secilen_urun,$yeni_ad,$yeni_stok,$yeni_fiyat,$yeni_kategori/" depo.csv
    
    zenity --info --text="Ürün başarıyla güncellendi!"
}

# Ürün silme fonksiyonu
urun_sil() {
    if [ "$KULLANICI_ROL" != "yonetici" ]; then
        zenity --error --text="Bu işlem için yönetici yetkisine sahip olmalısınız!"
        log_error "$AKTIF_KULLANICI" "Yetkisiz Erişim" "Ürün silme denemesi"
        return 1
    fi
    
    local urun_listesi=$(awk -F',' 'NR>1 {print $1 "|" $2 "|" $3 "|" $4 "|" $5}' depo.csv)
    
    local secilen=$(zenity --list \
        --title="Ürün Sil" \
        --text="Silmek istediğiniz ürünü seçin:" \
        --column="No" --column="Ürün Adı" --column="Stok" --column="Fiyat" --column="Kategori" \
        $(echo "$urun_listesi" | tr '|' ' ') \
        --width=600 --height=400)
    
    [ -z "$secilen" ] && return 1
    
    zenity --question --title="Silme Onayı" \
        --text="Bu ürünü silmek istediğinizden emin misiniz?\nBu işlem geri alınamaz!" \
        --ok-label="Evet" --cancel-label="Hayır" || return 1
    
    progress_bar "Ürün siliniyor"
    cp depo.csv yedekler/depo_$(date +%Y%m%d_%H%M%S).csv
    sed -i "/^$secilen,/d" depo.csv
    
    zenity --info --text="Ürün başarıyla silindi!"
}
