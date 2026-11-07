#!/bin/bash
# =====================================================================
# lab-check.sh  --  run as root on node1 AFTER a reboot.
#
# Confirms the lab is built correctly AND that everything survived the
# reboot. Run this again any time you suspect you have broken the lab.
# =====================================================================

pass() { printf '  \033[32m[ OK ]\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m[FAIL]\033[0m %s\n' "$1"; RC=1; }
sect() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
RC=0

sect "Identity"
[[ $(hostname -f) == node1.lab.example.com ]] \
  && pass "hostname is node1.lab.example.com" \
  || fail "hostname is $(hostname -f), expected node1.lab.example.com"

sect "Network"
ip -4 addr show | grep -q '172\.25\.250\.10/24' \
  && pass "172.25.250.10/24 is configured" \
  || fail "172.25.250.10/24 not found on any interface"
ping -c1 -W2 172.25.250.11 &>/dev/null \
  && pass "node2 reachable by IP" \
  || fail "cannot ping 172.25.250.11"
getent hosts node2.lab.example.com &>/dev/null \
  && pass "node2 resolves (/etc/hosts)" \
  || fail "node2.lab.example.com does not resolve"

sect "Storage - raw disks for the LVM/partition labs"
for d in sdb sdc sdd; do
  if lsblk -dno NAME | grep -qx "$d"; then
    if lsblk -no FSTYPE "/dev/$d" | grep -q .; then
      fail "/dev/$d exists but already has a filesystem/PV signature"
    else
      pass "/dev/$d present and raw"
    fi
  else
    fail "/dev/$d missing - add it in VMware VM Settings"
  fi
done

sect "Storage - free space left in vg_system for lvextend practice"
FREE=$(vgs --noheadings -o vg_free --units g vg_system 2>/dev/null | tr -dc '0-9.')
if [[ -n $FREE ]] && (( ${FREE%.*} >= 3 )); then
  pass "vg_system has ${FREE}G free"
else
  fail "vg_system has little/no free space (${FREE:-none}G)"
fi

sect "Software repositories"
mountpoint -q /mnt/dvd \
  && pass "DVD mounted at /mnt/dvd" \
  || fail "/mnt/dvd not mounted - is the ISO connected in VM Settings?"
grep -q '/mnt/dvd' /etc/fstab \
  && pass "DVD mount is persistent (in /etc/fstab)" \
  || fail "DVD mount missing from /etc/fstab"
dnf -q repolist 2>/dev/null | grep -qi baseos \
  && pass "dnf sees a BaseOS repo" \
  || fail "dnf cannot see BaseOS"
dnf -q -y install --downloadonly tree &>/dev/null \
  && pass "dnf can resolve and download packages" \
  || fail "dnf transaction test failed"

sect "Security baseline"
[[ $(getenforce) == Enforcing ]] \
  && pass "SELinux is Enforcing" \
  || fail "SELinux is $(getenforce) - it MUST be Enforcing"
systemctl is-active --quiet firewalld \
  && pass "firewalld is running" \
  || fail "firewalld is not running"
systemctl is-enabled --quiet firewalld \
  && pass "firewalld is enabled at boot" \
  || fail "firewalld is not enabled at boot"
systemctl is-active --quiet sshd \
  && pass "sshd is running" \
  || fail "sshd is not running"

sect "node2 services (reachable from node1)"
curl -sfI http://node2.lab.example.com/rhel10/BaseOS/ &>/dev/null \
  && pass "node2 HTTP repo answers" \
  || fail "http://node2.lab.example.com/rhel10/BaseOS/ unreachable"
if command -v showmount &>/dev/null; then
  showmount -e node2.lab.example.com 2>/dev/null | grep -q /exports \
    && pass "node2 NFS exports visible" \
    || fail "showmount found no exports on node2"
else
  echo "  [note] nfs-utils not installed on node1 - that is intentional."
  echo "         Installing it is Lab 1. Skipping the NFS check."
fi

sect "Boot target"
[[ $(systemctl get-default) == multi-user.target ]] \
  && pass "default target is multi-user.target" \
  || fail "default target is $(systemctl get-default)"

echo
if (( RC == 0 )); then
  printf '\033[32mLab is healthy. Take your BASELINE snapshot now.\033[0m\n'
else
  printf '\033[31mOne or more checks failed - fix before starting labs.\033[0m\n'
fi
exit $RC
