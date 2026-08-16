# VM setup for Inception

The subject requires the whole project to run inside a Virtual Machine, not on the
host. This campus machine can't use QEMU/KVM (no sudo, not in the `libvirt`/`kvm`
groups) and `/home` is quota-limited to a few GB, so:

- The VM disk lives on **`/goinfre`** (local scratch, not the quota'd home dir).
- **VirtualBox** is used (already installed and working here without sudo).
- The OS install is **fully unattended** (`VBoxManage unattended install` with our
  own `preseed.cfg`), so the whole VM — sudo, sshd, Docker, the cloned repo, all of
  it — can be rebuilt from nothing in one command if `/goinfre` ever gets wiped.
- The host's `/etc/hosts` can't be edited here (no sudo), so browser testing happens
  **inside the VM's own GUI**, hitting `https://nburchha.42.fr` via the guest's own
  `/etc/hosts` (which you fully control as root in the guest).

## First-time setup

```bash
./create-vm.sh          # creates the VM, downloads current Debian stable, unattended-installs it
```

That's it — no manual steps after this. A VirtualBox window opens showing the install
directly (`--start-vm=gui`). **Takes a while (~10-15 min for package downloads).**
`preseed.cfg` (passed via `--script-template`) takes care of everything a plain
install wouldn't:

- adds you to `sudo` and `docker` (the stock VirtualBox template puts you in a group
  called `admin`, which doesn't exist on Debian — a one-word bug, not a Debian thing)
- installs and enables `openssh-server` (Debian's installer only does this for a
  `minimal` install; a normal Desktop install skips it)
- installs `docker.io`, `docker-compose` (Debian's package name for the compose v2
  plugin — `docker-compose-plugin` only exists in Docker's own APT repo, not Debian's),
  `git`, `firefox-esr`
- adds the `nburchha.42.fr → 127.0.0.1` line to `/etc/hosts`
- clones the Inception repo to `~/Inception`

All via `d-i pkgsel/include` and the standard `in-target` late-command helper —
plain, native Debian preseed mechanisms, not custom scripting. See the comments in
`preseed.cfg` for exactly what changed from VirtualBox's stock template and why. We
initially tried `--post-install-command` instead, but that flag runs *unchrooted*,
against the live installer's own minimal environment rather than the target OS being
built — it reliably fails there, so we don't use it.

Once the VM reaches the login screen, log in — SSH and `make` work immediately:

```bash
ssh -p 2222 nburchha@localhost
cd ~/Inception && make
```

## Day-to-day use

`create-vm.sh` already leaves the VM running in `gui` mode after install, so nothing
extra is needed the first time. For later sessions:

**Only one session (headless *or* gui *or* separate) can hold the VM at a time.**
`--type separate` is not a way to attach a GUI to an already-running headless
session — it's just a third *starting* mode (like `gui`/`headless`), and it fails
with the same "already locked by a session" error if the VM is already running
under anything else. To switch modes, always power off first:

```bash
VBoxManage controlvm inception poweroff   # or shut down from inside the guest
```

- **Headless (SSH-only, for editing/checking files, running `make`, docker logs, etc.):**
  ```bash
  VBoxManage startvm inception --type headless
  ssh -p 2222 nburchha@localhost
  ```
- **GUI (to browse `https://nburchha.42.fr` and visually check WordPress):**
  ```bash
  VBoxManage startvm inception --type gui
  ```
  A VirtualBox window opens with the guest's GNOME desktop (installed by default by
  the unattended install) — open Firefox there.

- **Shut down:** `VBoxManage controlvm inception acpipowerbutton` (graceful) from the
  host, or just `sudo poweroff` inside the guest.

## Wiping the VM

```bash
./wipe-vm.sh    # confirms, then powers off + deletes the VM and its disk (keeps the cached ISO)
./create-vm.sh  # rebuild from scratch
```

Also use this if `/goinfre` itself gets wiped out from under a still-registered VM
(the script no-ops cleanly if the VM is already gone).

