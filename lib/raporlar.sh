#!/bin/bash

rapor_menu() {
    while true; do
        local secim=$(zenity --list \
            --title="Rapor Menüsü" \
            --text="Rapor türünü seçin:" \
            --column="İşlem" \
            "Stokta Azalan Ürünler" \
            "En Yüksek Stok Miktarına Sahip Ürünler" \
            "Toplam Değer Raporu" \
            "Kategori Bazlı Rapor" \
            "Ana Menüye Dön" \
            --width=400 --height=300)
        
        case $secim in
            "Stokta Azalan Ürünler") stok_azalan_rapor ;;
            "En Yüksek Stok Miktarına Sahip Ürünler") yuksek_stok_rapor ;;
            "Toplam Değer Raporu") toplam_deger_rapor ;;
            "Kategori Bazlı Rapor") kategori_rapor ;;
            "Ana Menüye Dön"|"") break ;;
        esac
    done
}

stok_azalan_rapor() {
    local esik=$(zenity --entry --title="Stok Eşiği" \
        --text="Minimum stok miktarını girin:" --entry-text="10")
    
    [ -z "$esik" ] && return 1
    
    local rapor=$(awk -F',' -v esik="$esik" '
        BEGIN {printf "%-8s %-20s %-12s %-12s %-15s\n", "No", "Ürün Adı", "Stok", "Fiyat", "Kategori"}
        NR>1 && $3 <= esik {printf "%-8s %-20s %-12s %-12s %-15s\n", $1, $2, $3, $4, $5}
    ' depo.csv)
    
    [ -z "$(echo "$rapor" | tail -n +2)" ] && {
        zenity --info --text="Stok miktarı $esik'in altında ürün bulunmamaktadır.";
        return 0;
    }
    
    zenity --text-info --title="Stokta Azalan Ürünler Raporu" \
        --width=700 --height=400 --font="monospace" \
        --filename=<(echo "$rapor")
}

yuksek_stok_rapor() {
    local limit=$(zenity --entry --title="Ürün Limiti" \
        --text="Kaç ürün gösterilsin?" --entry-text="5")
    
    [ -z "$limit" ] && return 1
    
    local rapor=$(awk -F',' '
        BEGIN {printf "%-8s %-20s %-12s %-12s %-15s\n", "No", "Ürün Adı", "Stok", "Fiyat", "Kategori"}
        NR>1 {print $0}
    ' depo.csv | sort -t',' -k3 -nr | head -n $limit | 
    awk -F',' '{printf "%-8s %-20s %-12s %-12s %-15s\n", $1, $2, $3, $4, $5}')
    
    zenity --text-info --title="En Yüksek Stoklu Ürünler" \
        --width=700 --height=400 --font="monospace" \
        --filename=<(echo "$rapor")
}

toplam_deger_rapor() {
    local rapor=$(awk -F',' '
        BEGIN {
            printf "%-30s %15s\n", "Metrik", "Değer"
            printf "%-30s %15s\n", "-------------------------------", "---------------"
            toplam_urun=0
            toplam_stok=0
            toplam_deger=0
        }
        NR>1 {
            toplam_urun++
            toplam_stok+=$3
            toplam_deger+=$3*$4
        }
        END {
            printf "%-30s %15d\n", "Toplam Ürün Çeşidi:", toplam_urun
            printf "%-30s %15d\n", "Toplam Stok Miktarı:", toplam_stok
            printf "%-30s %15.2f TL\n", "Toplam Stok Değeri:", toplam_deger
        }
    ' depo.csv)
    
    zenity --text-info --title="Toplam Değer Raporu" \
        --width=500 --height=300 --font="monospace" \
        --filename=<(echo "$rapor")
}
