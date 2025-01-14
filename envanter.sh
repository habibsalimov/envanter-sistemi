#!/bin/bash

# Renk tanımlamaları
KIRMIZI='\033[0;31m'
YESIL='\033[0;32m'
MAVI='\033[0;34m'
NORMAL='\033[0m'

# Global değişkenler
AKTIF_KULLANICI=""
KULLANICI_ROL=""
GIRIS_DENEME=0
MAX_GIRIS_HAKKI=3

# CSV dosya yapıları - Başlıkların doğru olduğundan emin olun
DEPO_BASLIK="UrunNo,UrunAdi,StokMiktari,BirimFiyat,Kategori"
KULLANICI_BASLIK="KullaniciNo,Ad,Soyad,Rol,Parola,Durum"
LOG_BASLIK="HataNo,Zaman,KullaniciAdi,Islem,Detay"

# Dosya yolları
export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DEPO_DOSYASI="$SCRIPT_DIR/depo.csv"
export KULLANICI_DOSYASI="$SCRIPT_DIR/kullanici.csv"
export LOG_DOSYASI="$SCRIPT_DIR/log.csv"

# Yardımcı fonksiyonlar
progress_bar() {
    local islem_adi=$1
    (
        echo "10" ; sleep 0.5
        echo "# $islem_adi - Hazırlanıyor..." ; sleep 0.5
        echo "50" ; sleep 0.5
        echo "# $islem_adi - İşleniyor..." ; sleep 0.5
        echo "90" ; sleep 0.5
        echo "# $islem_adi - Tamamlanıyor..." ; sleep 0.5
        echo "100"
    ) | zenity --progress --title="İşlem Durumu" --text="Başlatılıyor..." \
        --percentage=0 --auto-close --width=300
}

# Gerekli kontroller
check_requirements() {
    local gerekli_uygulamalar=("zenity" "md5sum" "awk" "grep")
    
    for uygulama in "${gerekli_uygulamalar[@]}"; do
        if ! command -v $uygulama &> /dev/null; then
            echo -e "${KIRMIZI}Hata: $uygulama yüklü değil!${NORMAL}"
            echo "Yüklemek için: sudo apt-get install $uygulama"
            exit 1
        fi
    done
}

# Hata yakalama
trap 'echo "Program beklenmedik şekilde sonlandı!"; exit 1' SIGINT SIGTERM
trap cleanup EXIT

# Clean-up fonksiyonu
cleanup() {
    rm -f /tmp/envanter_*
    rm -f *.lock
}

# Ana programı başlatma fonksiyonu
main() {
    clear
    echo -e "\033]0;Envanter Yönetim Sistemi\007"
    
    echo "=============================================="
    echo "       ENVANTER YÖNETİM SİSTEMİ v1.0"
    echo "=============================================="
    
    check_requirements
    setup_files
    
    # Login işlemini kontrol et
    while true; do
        login
        if [ $? -eq 0 ]; then
            break
        fi
    done
    
    # Başarılı girişten sonra ana menüyü göster
    ana_menu
}

# Ana menü fonksiyonu
ana_menu() {
    while true; do
        local secim=$(zenity --list --title="Ana Menü" \
            --text="Hoş geldiniz, $AKTIF_KULLANICI" \
            --column="İşlem" \
            "Ürün Ekle" \
            "Ürün Listele" \
            "Ürün Güncelle" \
            "Ürün Sil" \
            "Raporlar" \
            "Kullanıcı Yönetimi" \
            "Program Yönetimi" \
            "Çıkış" \
            --width=300 --height=400)
        
        case $secim in
            "Ürün Ekle") urun_ekle ;;
            "Ürün Listele") urun_listele ;;
            "Ürün Güncelle") urun_guncelle ;;
            "Ürün Sil") urun_sil ;;
            "Raporlar") rapor_menu ;;
            "Kullanıcı Yönetimi") kullanici_menu ;;
            "Program Yönetimi") program_menu ;;
            "Çıkış"|"") cikis ;;
        esac
    done
}

# Çıkış fonksiyonu
cikis() {
    zenity --question --title="Çıkış" \
        --text="Programdan çıkmak istediğinizden emin misiniz?" \
        --ok-label="Evet" --cancel-label="Hayır" || return 1
    
    progress_bar "Çıkış yapılıyor"
    cleanup
    
    zenity --info --title="Hoşça Kalın" \
        --text="Program kapatılıyor. İyi günler!"
    
    exit 0
}

# Fonksiyonlar
source "./lib/auth.sh"
[ -f "./lib/urun_islemleri.sh" ] || {
    zenity --error --text="Ürün işlemleri modülü bulunamadı!"
    exit 1
}
source "./lib/urun_islemleri.sh"
source "./lib/raporlar.sh"
source "./lib/kullanici_yonetimi.sh"
source "./lib/log_yonetimi.sh"
source "./lib/program_yonetimi.sh"

# Program başlangıcı
main
