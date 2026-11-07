# RHCSA Practice Lab — Build Guide
### RHEL 10 · VMware Workstation Pro / Fusion Pro · two nodes

---

## 0. Before you start

### Host requirements

| Item | Minimum | Comfortable |
|---|---|---|
| Free RAM | 6 GB | 16 GB |
| CPU cores | 4 | 8 |
| Free disk | 60 GB | 120 GB |
| Virtualization | VT-x / AMD-V enabled in BIOS | — |
| VMware | Workstation Pro 17.5+ / Fusion Pro 13.5+ | latest |

**Where the disk goes.** The two VMs *declare* 70 GB of virtual disk (node1: 20 + 10 + 5
+ 5, node2: 20 + 10), but VMware grows those files as they fill, and most of them stay
nearly empty:

| Item | Actual space used |
|---|---|
| RHEL 10 DVD ISO | ~12 GB |
| node1 after a minimal install | ~5 GB |
| node2 after install and services | ~6 GB |
| `sdb`/`sdc`/`sdd` while still raw | under 1 GB total |
| Each snapshot | 1 to 5 GB, growing as you work |

That is roughly 25 GB to get running. The 60 GB minimum leaves room for a few snapshots
and the storage labs filling those raw disks; 120 GB means never thinking about it. If
you keep the ISO on an external drive, subtract 12 GB.

**One hard gate for RHEL 10:** it requires an `x86-64-v3` CPU. In practice that means
an Intel Haswell (2013) or AMD Excavator/Zen (2015) or newer host. If your host CPU is
older, the installer will refuse to start and you should build the lab on RHEL 9
instead — the RHCSA objectives are effectively identical, and everything in this guide
works on 9 with only the ISO name changed.

Apple Silicon Macs: use the **aarch64** RHEL 10 ISO with Fusion. Everything below
applies except that virtual disks appear as `/dev/nvme*` or `/dev/sd*` depending on the
controller you pick — check with `lsblk` and adjust device names in the labs.

### What to download

1. A **Red Hat Developer Subscription for Individuals** — no cost, covers up to 16
   systems, and is the legitimate way to get RHEL ISOs and CDN access.
   Register at `developers.redhat.com`, then download from the Red Hat customer portal.
2. **RHEL 10 Binary DVD ISO** (roughly 10–12 GB). Get the *full DVD*, **not** the boot
   ISO — the DVD carries the BaseOS and AppStream repositories, which is what makes
   this lab work offline.

Put the ISO somewhere permanent. It stays attached to both VMs forever; it *is* your
package repository.

---

## 1. Lab topology

```
                 VMnet2 — host-only, 172.25.250.0/24, DHCP OFF
   ┌──────────────────────────┬──────────────────────────┐
   │                          │                          │
┌──┴───────────────────┐  ┌───┴──────────────────┐   ┌───┴────────────┐
│ node1                │  │ node2                │   │ your host      │
│ node1.lab.example.com│  │ node2.lab.example.com│   │ 172.25.250.1   │
│ 172.25.250.10        │  │ 172.25.250.11        │   │ (kickstart via │
│                      │  │                      │   │  HTTP, then    │
│ YOUR EXAM MACHINE    │  │ NFS server           │   │  stays out of  │
│ sda 20G  (OS)        │  │ HTTP repo            │   │  the way)      │
│ sdb 10G  raw         │  │ chrony time source   │   └────────────────┘
│ sdc  5G  raw         │  │ 2nd exam machine     │
│ sdd  5G  raw         │  │ sda 20G, sdb 10G raw │
└──────────────────────┘  └──────────────────────┘

              NO INTERNET  — exactly like the exam
```

Why host-only and not NAT: the real exam has no internet. If your lab has internet,
you will unconsciously lean on `dnf` reaching the CDN and on Googling syntax, and you
will discover on exam day that you never learned to drive `man -k`, `/usr/share/doc`,
and an offline repo. Build the constraint in from minute one.

---

## 2. Create the virtual network

You are creating one host-only network, `VMnet2`, with **DHCP turned off**, because
every RHCSA networking objective is about *static* configuration.

### Workstation Pro (Windows / Linux)

1. `Edit` → `Virtual Network Editor`
2. Click **Change Settings** (elevates to admin — required to add networks)
3. **Add Network…** → choose **VMnet2** → OK
4. Select VMnet2 and set:
   - Type: **Host-only** ("Connect a host virtual adapter to this network" **checked**)
   - "Use local DHCP service to distribute IP addresses" → **UNCHECKED**
   - Subnet IP: `172.25.250.0`  ·  Subnet mask: `255.255.255.0`
5. **Apply** → **OK**

### Fusion Pro (macOS)

1. `VMware Fusion` → `Settings…` → `Network`
2. Click the **padlock** and authenticate
3. Click **+** to create a new custom network (it will be named `vmnet2` or similar)
4. Configure:
   - "Allow virtual machines on this network to connect to external networks (NAT)" → **UNCHECKED**
   - "Connect the host Mac to this network" → **CHECKED**
   - "Provide addresses on this network via DHCP" → **UNCHECKED**
   - Subnet IP: `172.25.250.0`  ·  Subnet mask: `255.255.255.0`
5. **Apply**

### Confirm the host's address on that network

```bash
# Linux host
ip -4 addr show vmnet2
# macOS host
ifconfig vmnet2
```
```
:: Windows host (PowerShell)
ipconfig | findstr /C:"VMnet2" /A:4
```

You should see **172.25.250.1** on the host adapter. If VMware picked a different last
octet, note it — you need it for the kickstart URL in Step 4.

---

## 3. Create the VMs

Do this twice, once per node. The only differences are the name and the extra disks.

### 3.1 New VM wizard

| Wizard prompt | Choose |
|---|---|
| Configuration | **Custom (advanced)** |
| Hardware compatibility | Newest available (Workstation 17.x / Fusion 13.x) |
| Guest OS installation | **I will install the operating system later** |
| Guest OS | Linux → **Red Hat Enterprise Linux 10 64-bit** (pick 9 if 10 isn't listed) |
| Name | `node1` / `node2` |
| Processors | 1 processor × **2 cores** |
| Memory | **2048 MB** |
| Network type | **Custom: VMnet2** (Fusion: your new custom network) |
| I/O controller | **VMware Paravirtual** |
| Disk type | **SCSI** |
| Disk | Create a new virtual disk, **20 GB**, do *not* allocate now, single file is fine |

> **Do NOT pick LSI Logic SAS or LSI Logic Parallel.** Red Hat removed the `mptsas`
> and `mptspi` drivers, so RHEL 8/9/10 installers show an **empty disk list** on those
> controllers. **VMware Paravirtual** (`vmw_pvscsi`) is supported, and still presents
> disks as `/dev/sda`, `/dev/sdb`, `/dev/sdc`… which is what every lab in this set
> assumes.
>
> NVMe also works fine, but then your disks are `/dev/nvme0n1`, `/dev/nvme0n2`… and you
> must translate device names in every command, plus edit four lines in the kickstart
> (`ignoredisk`, `clearpart --drives`, the three `--ondisk`, and `bootloader
> --boot-drive`). Not wrong, just extra friction while a timer is running.

### 3.2 Firmware — do this before first boot

`VM Settings` → `Options` tab → `Advanced`:

- Firmware type: **UEFI**
- **Uncheck** "Enable secure boot"

Secure Boot off keeps custom kernel-arg and bootloader labs from fighting you.

### 3.3 Attach the ISO

`VM Settings` → `CD/DVD (SATA)`:

- **Connect at power on**: checked
- **Use ISO image file**: browse to your RHEL 10 DVD

Leave this attached permanently. It is the offline repo.

### 3.4 Add the extra disks

`VM Settings` → `Add…` → `Hard Disk` → **SCSI** → *Create a new virtual disk* → size →
*Store virtual disk as a single file* (do not pre-allocate).

**node1** — add three:

| Disk | Size | Becomes | Used for |
|---|---|---|---|
| 2 | 10 GB | `/dev/sdb` | GPT partitions, PV/VG/LV, `lvextend` |
| 3 | 5 GB | `/dev/sdc` | swap partition + swap LV, VFAT/ext4 |
| 4 | 5 GB | `/dev/sdd` | scratch — deliberately destroy and rebuild |

**node2** — add one:

| Disk | Size | Becomes | Used for |
|---|---|---|---|
| 2 | 10 GB | `/dev/sdb` | node2-side storage practice |

---

## 4. Path A — install with kickstart (fast, repeatable)

This is how you rebuild node1 in ~6 minutes after you have destroyed it, which you
will do often and on purpose.

### 4.1 Serve the kickstart files from your host

Put `ks-node1.cfg` and `ks-node2.cfg` in a folder on your host and run, **in that
folder**:

```bash
python3 -m http.server 8000 --bind 172.25.250.1
```

- macOS: `python3` is present out of the box.
- Windows: install Python from python.org, or run `npx http-server -p 8000` if you have
  Node.js. Also allow port 8000 through Windows Defender Firewall for **Private**
  networks when prompted.
- Verify from the host itself: `curl http://172.25.250.1:8000/ks-node1.cfg`

### 4.2 Boot the VM and point Anaconda at the kickstart

1. Power on the VM. Click inside the console window immediately (VMware only sends
   keystrokes to a focused guest, and the boot menu times out in 60 seconds).
2. At the GRUB boot menu, highlight **Install Red Hat Enterprise Linux 10** and press
   **`e`**.
3. Find the line beginning `linuxefi /images/pxeboot/vmlinuz …` and append, at the very
   end of that line, **both** arguments, on one line separated by a space:

   **node1:**
   ```
   ip=172.25.250.10::172.25.250.1:255.255.255.0:node1.lab.example.com:ens192:none inst.ks=http://172.25.250.1:8000/ks-node1.cfg
   ```

   **node2:**
   ```
   ip=172.25.250.11::172.25.250.1:255.255.255.0:node2.lab.example.com:ens192:none inst.ks=http://172.25.250.1:8000/ks-node2.cfg
   ```

4. Press **Ctrl-X** to boot.

The install runs unattended and reboots itself.

### Why `ip=` is not optional here

**Without it, the install fails.** You switched DHCP off on this VMnet in step 2, so the
installer boots with no address at all. It cannot reach `172.25.250.1:8000`, so it never
downloads the kickstart, and Anaconda drops you into the interactive installer as though
you had typed nothing. An installer that ignores `inst.ks` is almost always an installer
with no network.

`ip=` is what gives the installer an address *before* it fetches anything. The kickstart's
own `network --bootproto=static` line configures the installed system, which is a later
and separate step.

The fields are positional, colon-separated, and empty ones are skipped:

```
ip=<address>:<server>:<gateway>:<netmask>:<hostname>:<interface>:<autoconf>
   172.25.250.10 : (empty) : 172.25.250.1 : 255.255.255.0 : node1.lab.example.com : ens192 : none
```

- The **server** field is for boot servers such as NFS or TFTP. Empty here.
- The **gateway** is the host-only adapter. There is no route off this network, and that
  is the point, but the field wants a value and the adapter is the right one.
- `none` means "no autoconfiguration": use exactly the address given, do not try DHCP.

**Check the interface name before you type it.** These VMs come up as `ens192`, but the
name depends on the virtual NIC the wizard gave you. If the install stalls at the
kickstart download, switch to the installer's shell with **Ctrl-Alt-F2** and run:

```bash
ip link            # lists the interface names the installer can see
ip -4 addr         # did your ip= argument actually take effect?
```

Then reboot and retype the argument with the correct name. If you would rather not deal
with names at all, `ksdevice=link` plus `ip=dhcp` is the usual alternative, but it needs
a DHCP server, which this network deliberately does not have.

> **Reading the kickstart is part of the learning.** Open `ks-node1.cfg` and read the
> comments. The partition layout, the `ignoredisk` line, and the `%post` repo block are
> all things the exam expects you to build by hand.


---

## 5. Path B — install manually (do this at least once)

Anaconda is not on the exam, but you should see the layout your kickstart produces.
Boot the ISO with no extra arguments and work through these screens.

**Language / keyboard** — English (US), then **Continue**.

**Installation Destination**
- Select **only** the 20 GB disk. Leave `sdb`/`sdc`/`sdd` unselected — this is the
  manual equivalent of `ignoredisk --only-use=sda`.
- Storage Configuration → **Custom** → **Done**.
- On the manual partitioning screen, choose **LVM** from the scheme dropdown, then
  create:

| Mount point | Size | Type | FS |
|---|---|---|---|
| `/boot/efi` | 600 MiB | Standard Partition | EFI System Partition |
| `/boot` | 1 GiB | Standard Partition | xfs |
| `/` | 10 GiB | LVM (`vg_system`/`lv_root`) | xfs |
| swap | 2 GiB | LVM (`vg_system`/`lv_swap`) | swap |

- **Leave the remaining ~6 GiB unallocated inside `vg_system`.** Click the volume
  group's *Modify…* button and set size policy to **As large as possible** for the PV
  but do not grow the LVs. This free space is what you will practise `lvextend -r`
  against later. A lab with a full VG teaches you nothing.
- **Done** → **Accept Changes**.

**Software Selection** — **Minimal Install**, no add-ons. The exam machine is bare;
yours should be too.

> **node2 needs packages that Minimal Install does not provide.** Choose Minimal Install
> on node2 as well, but you must then install the service packages by hand before
> `node2-services.sh` will work. Section 7 has the command. The kickstart path installs
> them for you; this manual path does not.

**Network & Host Name**
- Host name: `node1.lab.example.com` → **Apply**
- Select the ethernet device → **Configure…** → **IPv4 Settings** tab → Method
  **Manual** → Add → Address `172.25.250.10`, Netmask `255.255.255.0`, leave Gateway
  and DNS **empty** → **Save**
- Toggle the interface **ON** and check "Connect automatically with priority"
- **Done**

**Root Account** — set password `redhat`, and tick **Allow root SSH login with
password** (lab convenience; you would never do this in production).

**User Creation** — `student` / `student`, tick **Make this user administrator**.

**Begin Installation** → reboot → remove nothing (the ISO stays attached).

For node2, repeat with hostname `node2.lab.example.com`, IP `172.25.250.11`, and a
12 GiB root.

---

## 6. First boot — wire up the offline repo

If you installed manually, the `%post` work did not happen. Do it by hand on **both**
nodes — and notice that this is itself an exam objective ("configure access to
repositories", "configure systems to mount file systems at boot").

```bash
# --- persistent DVD mount -------------------------------------------
mkdir -p /mnt/dvd
vim /etc/fstab
```
Add:
```
/dev/sr0  /mnt/dvd  iso9660  ro,nofail  0 0
```
```bash
systemctl daemon-reload
mount -a
findmnt /mnt/dvd            # verify

# --- repo definition -------------------------------------------------
vim /etc/yum.repos.d/lab-dvd.repo
```
```ini
[dvd-baseos]
name=RHEL 10 BaseOS (local DVD)
baseurl=file:///mnt/dvd/BaseOS
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[dvd-appstream]
name=RHEL 10 AppStream (local DVD)
baseurl=file:///mnt/dvd/AppStream
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```
```bash
dnf repolist                # verify: two repos, non-zero package counts
dnf -y install tree         # verify: a real transaction succeeds

# --- name resolution --------------------------------------------------
cat >> /etc/hosts <<'EOF'
172.25.250.10   node1.lab.example.com   node1
172.25.250.11   node2.lab.example.com   node2
EOF
getent hosts node2          # verify
```

`nofail` is the important detail: without it, a missing ISO drops the box into
emergency mode at boot. Learn that habit now, because it is exactly how people fail
the storage section of the exam.

---

## 7. Turn node2 into the services host

**If you installed node2 by hand (Path B), install the service packages first.** A
Minimal Install has no `httpd` and no `nfs-server`, so `node2-services.sh` would try to
start services that do not exist. Set up node2's own DVD repo as in section 6, then:

```bash
dnf install -y httpd nfs-utils chrony policycoreutils-python-utils rsync
```

Skip this if you used the kickstart: `ks-node2.cfg` already lists all five.

Now copy `node2-services.sh` onto node2 (`curl -O http://172.25.250.1:8000/node2-services.sh`
while the host web server is still running, or just retype it) and run it as root.

It configures the HTTP repo, the NFS exports, chrony, and firewalld, all persistently.
Read the script before running it; every block in it is an RHCSA-level task.

Then verify **from node2**:

```bash
systemctl is-active httpd nfs-server chronyd
exportfs -v
firewall-cmd --list-all
curl -sI http://localhost/rhel10/BaseOS/ | head -1
```

---

## 8. Verify, then reboot, then verify again

Copy `lab-check.sh` to node1, `chmod +x`, and run it as root.

Then — and this is the habit that passes the exam — **reboot both nodes and run it
again**:

```bash
reboot
# after it comes back:
./lab-check.sh
```

Every single RHCSA task is graded after a reboot on a freshly booted machine. A
configuration that works right now but is not persistent scores zero. Train the reflex:
*configure → verify → reboot → verify again.*

Note that `lab-check.sh` will report `nfs-utils not installed on node1`. That is
intentional. Installing it is your first lab.

---

## 9. Snapshots — your reset button

Take these on **both** VMs, powered off, in this order:

| Snapshot name | When | Why |
|---|---|---|
| `01-clean-install` | right after install, before any config | rebuild from scratch |
| `02-lab-baseline` | after `lab-check.sh` passes post-reboot | **your daily starting point** |

Workstation: `VM` → `Snapshot` → `Take Snapshot…`
Fusion: `Virtual Machine` → `Snapshots…` → `Take Snapshot`

Revert to `02-lab-baseline` before each practice session. You are going to corrupt
`/etc/fstab`, lock yourself out of the bootloader, and mislabel SELinux contexts on
purpose. That is the point. Snapshots make it free.

---

## 10. Confirm you can break in (root password recovery readiness)

Before your first study session, prove that boot interruption works in your setup —
this is a guaranteed exam-adjacent skill and VMware's fast boot can make the GRUB menu
hard to catch.

1. Power on node1 and click into the console window immediately.
2. If the GRUB menu flashes past, power off and edit
   `node1.vmx` (in the VM's folder, VM powered off) to add:

   ```
   bios.bootDelay = "5000"
   ```

   That gives you a 5-second pause at the VMware firmware screen so you can get your
   hands on the keyboard.
3. At the GRUB menu press **`e`**, append `rd.break` to the `linux` line, **Ctrl-X**.
4. You should land at a `switch_root:/#` prompt. If you do, your console access is
   good. Type `exit` twice to continue booting normally.

You will learn the full recovery procedure in the "Operate running systems" labs. For
now you are only confirming the plumbing works.

---

## 11. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Installer shows **no disks at all** | Controller is LSI Logic SAS/Parallel — unsupported on RHEL 8+. Change to **VMware Paravirtual** or NVMe. |
| Dracut emergency shell after changing controller type | initramfs lacks the new driver. Boot `inst.rescue`, `chroot /mnt/sysroot`, then `dracut -f --no-hostonly --regenerate-all`. |
| Installer says the CPU is unsupported | Host is older than x86-64-v3. Use RHEL 9. |
| Kickstart URL times out | Host firewall blocking 8000, or the host adapter isn't 172.25.250.1. Test `curl` from the host first. |
| `dnf repolist` shows 0 packages | ISO not connected, or `/mnt/dvd` not mounted. `findmnt /mnt/dvd`, then check *VM Settings → CD/DVD → Connected*. |
| GPG check fails | You are using a Rocky/Alma ISO with the Red Hat key path. Point `gpgkey=` at `/etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9` or equivalent. |
| Boots to emergency mode | Bad `/etc/fstab` line. At the emergency prompt: `mount -o remount,rw /`, fix fstab, `systemctl daemon-reload`, reboot. Always use `nofail` on removable media. |
| `sdb`/`sdc`/`sdd` missing | Disks added while powered on and not rescanned, or added to the wrong VM. Power cycle. |
| Nodes can't ping each other | One NIC is on VMnet8/NAT instead of VMnet2. Check *VM Settings → Network Adapter*. |
| Console keystrokes ignored | Click inside the guest window. `Ctrl+Alt` releases the pointer. |
| GRUB menu too fast to catch | `bios.bootDelay = "5000"` in the `.vmx`, or `grub2-editenv - unset menu_auto_hide` inside the guest. |

---

## 12. Your daily lab workflow

1. Revert both VMs to `02-lab-baseline`.
2. Power on node2 first, then node1.
3. Work **only** from the VMware console or from `ssh student@node1` — never copy-paste
   from a browser. Typing the commands is the training.
4. `man`, `man -k`, `info`, and `/usr/share/doc` are your only documentation, because
   they are your only documentation on exam day.
5. Finish every task with a verification command, then reboot and re-verify.
6. When you break something badly, fix it if you can — that *is* the exam — and revert
   only when you are truly stuck.

---

## Files in this set

| File | Runs where | Purpose |
|---|---|---|
| `LAB-BUILD-GUIDE.md` | host | this document |
| `ks-node1.cfg` | served from host | unattended install of node1 |
| `ks-node2.cfg` | served from host | unattended install of node2 |
| `node2-services.sh` | node2, as root | HTTP repo, NFS, chrony, firewall |
| `lab-check.sh` | node1, as root | full lab health + persistence check |

---

## Credentials

| Account | Password | Notes |
|---|---|---|
| `root` | `redhat` | SSH password login permitted (lab only) |
| `student` | `student` | member of `wheel`, full sudo |
| `remuser` (node2) | — | uid 5000, NFS home at `/exports/home/remuser` |
