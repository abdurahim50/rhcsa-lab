# Lab assets

Everything needed to build the two-VM environment. The full walkthrough, including the VMware
click-paths, is in [`../docs/lab-build-guide.md`](../docs/lab-build-guide.md).

## Kickstart

Unattended installs. Serve them over HTTP from your host and point the installer at them with
`inst.ks=`:

```bash
# on your host, in the kickstart directory
python3 -m http.server 8000

# at the RHEL installer boot prompt, press 'e' and append to the linux line:
#   inst.ks=http://172.25.250.1:8000/ks-node1.cfg
```

| File | Builds |
|---|---|
| `ks-node1.cfg` | node1, the exam machine. Minimal packages, `sdb`/`sdc`/`sdd` left raw, ~6 GB free in the volume group |
| `ks-node2.cfg` | node2, the services host. Adds `httpd`, `nfs-utils`, `chrony`, `policycoreutils-python-utils`, `rsync` |

Both set `root:redhat` and `student:student` in plaintext. See the warning in the
[top-level README](../README.md#a-note-on-the-credentials-in-this-repository) before reusing them
anywhere that is not a disposable VM on an isolated network.

## Scripts

All three run as root. Copy them to the node with `scp`, or retype them; they are short.

| Script | Run on | When |
|---|---|---|
| `lab-bringup.sh` | either node | After a manual (non-kickstart) install, to reach the same state the kickstart would have produced: hostname, static IP, `/etc/hosts`, DVD repository |
| `node2-services.sh` | node2 only | Once, after install. Sets up the HTTP package repository, NFS exports, `remuser` (uid 5000), chrony, and firewalld |
| `lab-check.sh` | node1 | After every reboot, and any time something stops working. Checks health and persistence |

```bash
./lab-bringup.sh node1        # or: ./lab-bringup.sh node2
./node2-services.sh           # node2, once
./lab-check.sh                # node1, after a reboot
```

`lab-check.sh` is read-only. The other two change system state; read them before running them,
which is good practice generally and good exam preparation specifically.

## After the build

Snapshot both VMs and name the snapshot something like `clean-build`. Every section's exam assumes
a clean machine, and reverting is faster than undoing a section's worth of changes by hand.
