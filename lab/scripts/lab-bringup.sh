#!/bin/bash
# =====================================================================
# lab-bringup.sh  --  run as root on a MANUALLY installed node.
#
# Brings a hand-installed node1 or node2 to the same state the kickstart
# %post section would have produced:
#     * correct FQDN
#     * static IPv4 on the lab network (no gateway, no DNS - offline lab)
#     * /etc/hosts entries for both nodes
#     * persistent DVD mount + offline BaseOS/AppStream repo
#
#   ./lab-bringup.sh node1
#   ./lab-bringup.sh node2
#
# Safe to re-run. It replaces its own previous entries rather than
# appending duplicates.
#
# ---------------------------------------------------------------------
# THE MANUAL EQUIVALENT, if you would rather type it yourself (and you
# should, at least once - all of this is on the exam):
#
#   hostnamectl hostname node1.lab.example.com
#   nmcli con show
#   nmcli con mod <NAME> ipv4.method manual \
#         ipv4.addresses 172.25.250.10/24 \
#         ipv4.gateway "" ipv4.dns "" connection.autoconnect yes
#   nmcli con up <NAME>
#   mkdir -p /mnt/dvd
#   vim /etc/fstab      # /dev/sr0 /mnt/dvd iso9660 ro,nofail 0 0
#   systemctl daemon-reload && mount -a
#   vim /etc/yum.repos.d/lab-dvd.repo
#   dnf repolist
# =====================================================================
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root."; exit 1; }

NODE="${1:-}"
case "$NODE" in
  node1) IP=172.25.250.10 ;;
  node2) IP=172.25.250.11 ;;
  *) echo "Usage: $0 {node1|node2}"; exit 1 ;;
esac
FQDN="${NODE}.lab.example.com"

echo "==> Configuring ${FQDN} (${IP}/24)"
echo "    NOTE: if you are connected over SSH, the address change will"
echo "    drop your session. Run this from the VMware console."
echo

# --- 1. Hostname -----------------------------------------------------
hostnamectl hostname "$FQDN"
echo "[ok] hostname -> $(hostname -f)"

# --- 2. Static IPv4 --------------------------------------------------
# No gateway and no DNS on purpose: the lab is isolated and name
# resolution comes from /etc/hosts. A bogus gateway would make every
# lookup hang for seconds.
DEV=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="ethernet"{print $1; exit}')
[[ -n ${DEV:-} ]] || { echo "No ethernet device found. Check VM Settings -> Network Adapter."; exit 1; }

CON=$(nmcli -t -f NAME,DEVICE con show | awk -F: -v d="$DEV" '$2==d{print $1; exit}')
if [[ -z ${CON:-} ]]; then
    echo "    no connection profile bound to $DEV - creating one"
    nmcli con add type ethernet ifname "$DEV" con-name "$DEV"
    CON="$DEV"
fi
echo "    device=$DEV  profile=$CON"

nmcli con mod "$CON" \
      ipv4.method manual \
      ipv4.addresses "${IP}/24" \
      ipv4.gateway "" \
      ipv4.dns "" \
      connection.autoconnect yes
nmcli con up "$CON" >/dev/null
echo "[ok] $(ip -4 -br addr show "$DEV")"

# --- 3. Name resolution ----------------------------------------------
sed -i '/lab\.example\.com/d;/# RHCSA practice lab/d' /etc/hosts
cat >> /etc/hosts <<'EOF'
# RHCSA practice lab
172.25.250.10   node1.lab.example.com   node1
172.25.250.11   node2.lab.example.com   node2
EOF
getent hosts node1 node2
echo "[ok] /etc/hosts"

# --- 4. Persistent DVD mount -----------------------------------------
# nofail matters: without it, a detached ISO drops the box into
# emergency mode at boot. This is the single most common self-inflicted
# wound in the storage section of the exam.
mkdir -p /mnt/dvd
sed -i '\|[[:space:]]/mnt/dvd[[:space:]]|d' /etc/fstab
echo '/dev/sr0  /mnt/dvd  iso9660  ro,nofail  0 0' >> /etc/fstab
systemctl daemon-reload
mountpoint -q /mnt/dvd || mount /mnt/dvd
findmnt /mnt/dvd || { echo "DVD not mounted - is the ISO connected in VM Settings?"; exit 1; }
echo "[ok] /mnt/dvd (persistent)"

# --- 5. Offline repository -------------------------------------------
GPG=/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
[[ -f $GPG ]] || GPG=$(ls /etc/pki/rpm-gpg/RPM-GPG-KEY-* 2>/dev/null | head -1)

cat > /etc/yum.repos.d/lab-dvd.repo <<EOF
[dvd-baseos]
name=RHEL BaseOS (local DVD)
baseurl=file:///mnt/dvd/BaseOS
enabled=1
gpgcheck=1
gpgkey=file://${GPG}

[dvd-appstream]
name=RHEL AppStream (local DVD)
baseurl=file:///mnt/dvd/AppStream
enabled=1
gpgcheck=1
gpgkey=file://${GPG}
EOF

dnf clean all >/dev/null
dnf -q repolist
echo "[ok] offline repo"

# --- 6. Convenience --------------------------------------------------
cat > /etc/profile.d/lab.sh <<'EOF'
alias ll='ls -lh --color=auto'
export EDITOR=vi
EOF

echo
echo "===================== ${FQDN} ready ====================="
echo "Next:"
if [[ $NODE == node2 ]]; then
echo "  1. dnf -y install httpd nfs-utils chrony policycoreutils-python-utils rsync"
echo "  2. ./node2-services.sh"
else
echo "  1. ./lab-check.sh"
fi
echo "  Then REBOOT and run the checks again. Persistence is the whole game."
echo "========================================================="
