# prepare_ssh

Menyiapkan settingan SSH dan Fail2ban untuk LXC Debian 13 (fresh install).

Script ini akan:
- ✅ Menginstal **Git** dan **Fail2ban**
- ✅ Mengubah `PermitRootLogin prohibit-password` menjadi `PermitRootLogin yes` di `/etc/ssh/sshd_config`
- ✅ Mengaktifkan **Fail2ban** dengan jail `sshd` (maxretry=3, bantime=24h) sebagai proteksi anti-bruteforce
- ✅ Membuat backup otomatis `sshd_config` sebelum diubah
- ✅ Memvalidasi konfigurasi SSH (`sshd -t`) sebelum restart, rollback jika invalid

## Prasyarat

- LXC Debian 13 minimal, akses **root**
- Koneksi internet untuk `apt-get` dan mengambil script
- `curl` (akan diinstal otomatis jika belum ada)

## Instalasi Cepat (One-liner)

```bash
apt-get update && apt-get install -y curl && \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginanjardwibasuki/prepare_ssh/main/prepare_ssh.sh)"
