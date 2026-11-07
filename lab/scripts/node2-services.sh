#!/bin/bash
# =====================================================================
# node2-services.sh  --  run as root ON node2 ONLY, once, after install.
#
# Turns node2 into the infrastructure the exam assumes already exists:
#   * HTTP repository  ->  http://node2.lab.example.com/rhel10/{BaseOS,AppStream}
#   * NFS exports      ->  /exports/share, /exports/private, /exports/home
#   * NTP time source  ->  chrony serving 172.25.250.0/24
#
# Everything it configures is persistent across reboot.
#   curl -O http://172.25.250.1:8000/node2-services.sh   (or just retype it)
#   chmod +x node2-services.sh && ./node2-services.sh
# =====================================================================
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root."; exit 1; }
[[ $(hostname -s) == "node2" ]] || { echo "This script is for node2 only."; exit 1; }

echo "==> 1. Re-mounting the DVD with an httpd-friendly SELinux context"
# iso9660 has no xattrs, so the whole mount gets one context via context=.
# A bind mount then exposes it under the web root, inheriting that context.
sed -i '\|/mnt/dvd|d;\|/var/www/html/rhel10|d' /etc/fstab
mkdir -p /mnt/dvd /var/www/html/rhel10
cat >> /etc/fstab <<'EOF'
/dev/sr0  /mnt/dvd              iso9660  ro,nofail,context="system_u:object_r:httpd_sys_content_t:s0"  0 0
/mnt/dvd  /var/www/html/rhel10  none     bind,nofail                                                   0 0
EOF
umount /var/www/html/rhel10 2>/dev/null || true
umount /mnt/dvd             2>/dev/null || true
systemctl daemon-reload
mount -a
findmnt /mnt/dvd
findmnt /var/www/html/rhel10

echo "==> 2. Starting httpd"
systemctl enable --now httpd

echo "==> 3. Creating NFS exports"
mkdir -p /exports/share /exports/private /exports/home
echo "Shared read-write export on node2."   > /exports/share/README.txt
echo "Direct-map autofs target on node2."   > /exports/private/README.txt
chmod 0777 /exports/share

# A remote user whose home directory lives on NFS (for autofs home labs).
# Create the SAME uid/gid on node1 when a lab asks for it.
getent group  remgrp  >/dev/null || groupadd -g 5000 remgrp
getent passwd remuser >/dev/null || useradd  -u 5000 -g 5000 -d /exports/home/remuser -M remuser
mkdir -p /exports/home/remuser
cp -n /etc/skel/.bash* /exports/home/remuser/ 2>/dev/null || true
echo "This home directory is served over NFS from node2." > /exports/home/remuser/README.txt
chown -R 5000:5000 /exports/home/remuser
chmod 0700 /exports/home/remuser

cat > /etc/exports <<'EOF'
/exports          172.25.250.0/24(rw,sync,no_root_squash,crossmnt)
/exports/share    172.25.250.0/24(rw,sync,no_root_squash)
/exports/private  172.25.250.0/24(rw,sync,no_root_squash)
/exports/home     172.25.250.0/24(rw,sync,no_root_squash)
EOF

systemctl enable --now nfs-server
exportfs -rav

echo "==> 4. chrony as a lab time source"
if ! grep -q '^allow 172.25.250.0/24' /etc/chrony.conf; then
cat >> /etc/chrony.conf <<'EOF'

# --- RHCSA lab: serve time to the isolated lab network ---
allow 172.25.250.0/24
local stratum 10
EOF
fi
systemctl enable --now chronyd
systemctl restart chronyd

echo "==> 5. Firewall"
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=ntp
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
firewall-cmd --list-all

echo
echo "==================== node2 is ready ===================="
echo "HTTP repo : http://node2.lab.example.com/rhel10/BaseOS"
echo "            http://node2.lab.example.com/rhel10/AppStream"
echo "NFS       : showmount -e node2.lab.example.com"
echo "Time      : chronyc clients   (after node1 points at node2)"
echo
echo "Now REBOOT node2 and re-run the checks -- persistence is the"
echo "single most common reason people fail the RHCSA."
echo "========================================================"
