#!/bin/bash
# auto_prepare.sh
# Dijalankan di dalam LXC Debian 13 (fresh install)
# - Install Git
# - Ubah PermitRootLogin menjadi yes
# - Aktifkan Fail2ban (anti-bruteforce)

set -euo pipefail

# Pastikan dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo "Script harus dijalankan sebagai root (gunakan sudo atau login root)."
   exit 1
fi

echo "=== [1/6] Memperbarui daftar paket ==="
apt-get update

echo "=== [2/6] Menginstal paket yang dibutuhkan (git, fail2ban) ==="
apt-get install -y git fail2ban

echo "=== [3/6] Mengubah konfigurasi SSH: PermitRootLogin yes ==="
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_SSH="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"

if [[ ! -f "$SSHD_CONFIG" ]]; then
    echo "ERROR: $SSHD_CONFIG tidak ditemukan. Pastikan paket openssh-server terinstal."
    exit 1
fi

# Backup file asli
cp -a "$SSHD_CONFIG" "$BACKUP_SSH"
echo "Backup sshd_config dibuat: $BACKUP_SSH"

# Ubah atau tambahkan PermitRootLogin yes
if grep -qE '^\s*#?\s*PermitRootLogin' "$SSHD_CONFIG"; then
    sed -i -E 's/^\s*#?\s*PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin yes" >> "$SSHD_CONFIG"
fi

echo "=== [4/6] Validasi konfigurasi SSH & restart service ==="
if ! sshd -t; then
    echo "Konfigurasi SSH tidak valid. Mengembalikan backup..."
    cp -a "$BACKUP_SSH" "$SSHD_CONFIG"
    exit 1
fi

systemctl restart ssh
echo "SSH di-restart. PermitRootLogin sekarang: $(sshd -T | grep -i permitrootlogin || true)"

echo "=== [5/6] Membuat konfigurasi jail.local untuk Fail2ban ==="
JAIL_LOCAL="/etc/fail2ban/jail.local"
if [[ ! -f "$JAIL_LOCAL" ]]; then
    cat > "$JAIL_LOCAL" <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 3
findtime = 5m
bantime = 24h
EOF
    echo "File jail.local dibuat."
else
    echo "File jail.local sudah ada, tidak ditimpa."
fi

echo "=== [6/6] Mengaktifkan & menjalankan Fail2ban ==="
systemctl enable fail2ban
systemctl restart fail2ban

echo "Status Fail2ban (jail sshd):"
fail2ban-client status sshd || true

echo ""
echo "=== Selesai ==="
echo "Git          : $(git --version 2>/dev/null || echo 'TIDAK terinstal')"
echo "SSH          : PermitRootLogin = yes"
echo "Fail2ban     : aktif (jail sshd, maxretry=3, bantime=24h)"
echo ""
echo "PENTING: Pastikan Anda punya akses lain (misal console LXC) sebelum logout,"
echo "karena mengaktifkan root login via password meningkatkan risiko keamanan."
