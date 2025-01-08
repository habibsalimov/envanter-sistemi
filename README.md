# Envanter Yönetim Sistemi

Bash tabanlı, kullanıcı dostu grafiksel arayüze sahip bir envanter yönetim sistemi.

## Özellikler

- Grafiksel kullanıcı arayüzü (Zenity)
- Çok kullanıcılı yetkilendirme sistemi
- Ürün yönetimi (ekleme, silme, güncelleme, listeleme)
- Kullanıcı yönetimi
- Otomatik yedekleme
- Detaylı log kaydı
- Güvenlik önlemleri

## Tanıtım Videosu

Sistemin detaylı tanıtımı ve kullanımı için aşağıdaki YouTube videosunu izleyebilirsiniz:

[🎥 Envanter Yönetim Sistemi Tanıtım Videosu](https://youtu.be/kqi5KGk-8bU)

## Gereksinimler

- Bash 4.0+
- Zenity
- md5sum
- awk
- grep

## Kurulum

1. Sisteminizde gerekli paketlerin yüklü olduğundan emin olun:
```bash
sudo apt-get update
sudo apt-get install zenity
```

2. Projeyi klonlayın:
```bash
git clone https://github.com/habibsalimov/envanter-sistemi.git
cd envanter-sistemi
```

3. Çalıştırma izinlerini ayarlayın:
```bash
chmod +x envanter.sh
chmod +x lib/*.sh
```

## Kullanım

Programı başlatmak için:
```bash
./envanter.sh
```

İlk çalıştırmada otomatik olarak:
- Gerekli dosyalar ve dizinler oluşturulur
- İlk yönetici kullanıcısı tanımlamanız istenir

## Dizin Yapısı

```
envanter-sistemi/
├── envanter.sh         # Ana program
├── lib/                # Kütüphane dosyaları
│   ├── auth.sh        # Kimlik doğrulama
│   ├── setup.sh       # Kurulum işlemleri
│   ├── urun_islemleri.sh  # Ürün yönetimi
│   └── kullanici_yonetimi.sh  # Kullanıcı yönetimi
├── depo.csv           # Ürün veritabanı
├── kullanici.csv      # Kullanıcı veritabanı
├── log.csv           # İşlem kayıtları
└── yedekler/         # Otomatik yedekler
```

## Güvenlik

- MD5 ile şifrelenmiş parolalar
- Oturum yönetimi
- Yetkilendirme sistemi
- Başarısız giriş denemesi sınırlaması
- Otomatik hesap kilitleme

