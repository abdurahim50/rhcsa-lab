# Troubleshooting

Problems hit while building and running this lab, with the diagnosis and the fix. Each one cost real time, and several look like a broken command when the cause is somewhere else entirely.

## The installer shows no disks

**Symptom.** RHEL 10 reaches the installation destination screen and the disk list is empty, although the VM has disks attached.

**Cause.** The SCSI controller type. Red Hat removed the `mptsas` and `mptspi` drivers in RHEL 8, so **LSI Logic SAS** and **LSI Logic Parallel** present disks the installer cannot see. VMware's New Virtual Machine wizard still recommends LSI Logic by default.

**Fix.** Use **VMware Paravirtual** (the `vmw_pvscsi` driver). Disks appear as `/dev/sda`, `/dev/sdb`, and so on, which is what every file in this repository assumes.

NVMe also works, but it renames the devices to `/dev/nvme0n1` and similar, so every path in the labs and graders would need adjusting. Use Paravirtual.

## Mounting the DVD fails with "wrong fs type, bad option, bad superblock"

**Symptom.** On node2, mounting the ISO with an SELinux context fails:

```
mount -t iso9660 -o ro,context=system_u:object_r:httpd_sys_content_t:s0 /dev/sr0 /mnt/dvd
mount: /mnt/dvd: wrong fs type, bad option, bad superblock on /dev/sr0 ...
```

`blkid /dev/sr0` reports a perfectly valid `iso9660` filesystem, so the error message is misleading.

**Diagnosis.** The real reason is in the kernel log:

```bash
dmesg | tail
# SELinux: mount invalid.  Same superblock, different security settings
#   for (dev sr0, type iso9660)
```

`udisks` had already auto-mounted the disc at `/run/media/root/RHEL-10-...`. One block device has one superblock, and a superblock can carry only one set of SELinux settings. The second mount asked for different ones, so the kernel refused.

**Fix.** Unmount the auto-mount first, then mount once with the context you want:

```bash
findmnt /dev/sr0                       # find where udisks put it
umount /run/media/root/RHEL-10-*       # or whatever findmnt reported
mkdir -p /mnt/dvd
mount -t iso9660 -o ro,context=system_u:object_r:httpd_sys_content_t:s0 /dev/sr0 /mnt/dvd
mount --bind /mnt/dvd /var/www/html/rhel10
```

**Still open.** `udisks` can re-mount `/dev/sr0` at boot, which brings the problem back. If the repository stops working after a reboot, check `findmnt /dev/sr0` before anything else.

**What this teaches, beyond the lab.** `context=` exists for filesystems that cannot store SELinux labels themselves: `iso9660`, `vfat`, and NFS. On those, the label is supplied at mount time and applies to the whole mount.

## GRUB auto-selects before you can press a key

**Symptom.** The boot menu says the entry will boot automatically in one second, which is not enough time to interrupt the boot and reach `rd.break`. Several RHCSA objectives need you to interrupt the boot.

**Cause.** Three separate layers each set part of this, and changing only the first does nothing.

**Fix.** All three, in order:

```bash
vim /etc/default/grub
#   GRUB_TIMEOUT=10
#   GRUB_TIMEOUT_STYLE=menu

grub2-mkconfig -o /boot/grub2/grub.cfg    # regenerate the real config
grub2-editenv - unset menu_auto_hide      # clear the override in grubenv
```

| Layer | File | What it is |
|---|---|---|
| Source | `/etc/default/grub` | What you edit. Nothing reads it at boot |
| Generated | `/boot/grub2/grub.cfg` | What GRUB actually reads. Built by `grub2-mkconfig` |
| Environment | `grubenv` | Runtime overrides, edited with `grub2-editenv`, and it wins |

This three-layer pattern is itself an exam topic. Editing the source file and forgetting to regenerate is one of the most common ways to lose bootloader points.

## `mount -a` reports success but the filesystem is not mounted

**Symptom.** You add a line to `/etc/fstab`, run `mount -a`, see no error, and the filesystem still is not there.

**Cause.** `mount -a` does not stop at the first failure, and output from a successful mount looks like no output at all. An error for one entry scrolls past while later entries succeed.

**Fix.** Verify explicitly rather than trusting the absence of an error:

```bash
findmnt /your/mount/point       # nothing printed means it is not mounted
mount -a && echo OK             # exit status, not silence
systemctl daemon-reload         # after any fstab edit
```

In `findmnt` output, read the SOURCE column: a value in brackets, such as `/dev/sda1[/subdir]`, means that entry is a bind mount.

**Why this matters on the exam.** A bad `/etc/fstab` line can stop the system from booting, and every storage task is graded after a reboot. Always test with `mount -a` *and* `findmnt` before you reboot.

## RHEL 10 will not install: unsupported CPU

**Symptom.** The installer refuses to start, or the VM fails to boot the installation media on an older host.

**Cause.** RHEL 10 requires the **x86-64-v3** microarchitecture level: roughly Intel Haswell (2013) or AMD Zen and newer.

**Fix.** Use RHEL 9 instead. The objectives are nearly identical, and everything in this repository works on 9 apart from the Flatpak objectives in section 02.

## `subscription-manager` warnings on every `dnf` command

**Symptom.** Every `dnf` run prints a complaint about the system not being registered.

**Cause.** The lab nodes are deliberately unregistered and use a local DVD repository instead.

**Fix.** Cosmetic, and safe to ignore. To silence it:

```bash
subscription-manager config --rhsm.manage_repos=0
```

## Network configuration does not survive a reboot

**Symptom.** The IP address is right until you reboot, then it is gone.

**Cause.** Either the address was set with `ip addr add`, which is runtime-only and never persists, or the connection profile has autoconnect turned off.

**Fix.** Configure with `nmcli` or `nmtui`, which write a persistent profile, and confirm autoconnect is on:

```bash
nmcli connection show
nmcli -f connection.autoconnect connection show ens192
nmcli connection modify ens192 connection.autoconnect yes
```

In `nmtui`, the box to check is `[X] Automatically connect` on the Edit Connection screen.

**Note the interface name.** It is `ens192` on these VMs with the Paravirtual controller, not `ens160`. Always check with `nmcli device status` rather than assuming.

## General method

When something fails, work in this order:

1. **Read the actual error**, not the first thing that looks like an error.
2. **Check `dmesg` and `journalctl -xe`.** The DVD mount failure above is invisible in the `mount` output and obvious in `dmesg`.
3. **Verify the state you think you created**, with `findmnt`, `lsblk`, `systemctl status`, `nmcli connection show`, `getenforce`, or whatever fits.
4. **Reboot and check again.** On the exam, work that does not survive a reboot does not count.
