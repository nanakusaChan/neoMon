# 🧠 NEOMON - Hacker Style System Monitor
# a project by Nanakusa Chan
# please open the installer for load the project to your computer...

![NEOMON Demo](docs/demo.gif)

Gerçek zamanlı sistem izleme aracı. CPU, RAM, Disk, Network ve Process takibi yapar. Hacker theme'li ve Matrix efekti ile süslü.

## ✨ Özellikler

### 🟢 Core Features
- CPU, RAM, Disk, Swap kullanımı
- Upload/Download hızı ve toplam trafik
- Aktif bağlantı ve açık port sayısı
- Sistem uptime ve boot zamanı
- En çok CPU/RAM kullanan processler

### 🟡 Hacker Style
- Matrix yağmur efekti
- Animasyonlu progress barlar
- 4 farklı tema (Green Hacker, Cyberpunk, Minimal, Red Alert)
- Retro terminal görünümü

## 🚀 Kurulum (Arch CachyOS)

```bash
# Repoyu klonla
git clone https://github.com/nanakusaChan/neomon.git
cd neomon

# Python bağımlılıklarını kur
pip install -r backend/requirements.txt

# Backend'i başlat
cd backend
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Tarayıcıda aç
# http://localhost:8000
