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
    [ ! -s depo.csv ] && { zenity --info --text="Henüz kayıtlı ürün bulunmamaktadır."; return 1; }
    
    local liste=$(awk -F',' 'BEGIN {printf "%-8s %-20s %-12s %-12s %-15s\n", "No", "Ürün Adı", "Stok", "Fiyat", "Kategori"}
        NR>1 {printf "%-8s %-20s %-12s %-12s %-15s\n", $1, $2, $3, $4, $5}' depo.csv)
    
    zenity --text-info --title="Ürün Listesi" --width=600 --height=400 \
        --font="monospace" --filename=<(echo "$liste")
}

# Ürün güncelleme fonksiyonu
urun_guncelle() {
    # ...existing code for permission check...
    
    local urun_listesi=$(awk -F',' 'NR>1 {print $1 "|" $2}' depo.csv)
    local secilen_urun=$(zenity --list --title="Ürün Güncelle" \
        --text="Güncellenecek ürünü seçin:" \
        --column="No" --column="Ürün Adı" \
        $(echo "$urun_listesi" | tr '|' ' ') \
        --width=400 --height=300)
    
    [ -z "$secilen_urun" ] && return 1
    
    # ...existing code for update form and validation...
    
    progress_bar "Ürün güncelleniyor"
    sed -i "s/^$secilen_urun,.*/$secilen_urun,$urun_adi,$yeni_stok,$yeni_fiyat,$yeni_kategori/" depo.csv
    
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
