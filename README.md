# Envanter Yönetim Sistemi

Zenity tabanlı basit bir envanter yönetim sistemi. Linux sistemlerde çalışır.

## Özellikler

- Ürün yönetimi (ekleme, silme, güncelleme, listeleme)
- Kullanıcı yönetimi
- Raporlama sistemi
- Yedekleme ve geri yükleme
- Hata takibi
- Güvenli giriş sistemi

## Gereksinimler

- Linux işletim sistemi
- Zenity
- Bash shell
- md5sum
- awk
- grep

## Kurulum

1. Depoyu klonlayın:
```bash
git https://github.com/habibsalimov/envanter-sistemi.git
```

2. Dizine gidin:
```bash
cd envanter-sistemi
```

3. Çalıştırma izni verin:
```bash
chmod +x envanter.sh
```

4. Programı çalıştırın:
```bash
./envanter.sh
```

## Kullanım

1. Program ilk çalıştırıldığında otomatik olarak gerekli CSV dosyaları oluşturulur
2. Varsayılan yönetici hesabı:
   - Kullanıcı adı: admin
   - Şifre: admin123

## Dosya Yapısı

- `envanter.sh`: Ana program
- `lib/`: Program modülleri
- `*.csv`: Veri dosyaları

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
