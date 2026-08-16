#!/bin/bash
# Creates and unattended-installs the Inception VM via VBoxManage.
# Everything lives on /goinfre (home quota is too small for a VM disk).
# Rerun this from scratch any time /goinfre gets wiped.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESEED="${SCRIPT_DIR}/preseed.cfg"

VM_NAME="inception"
VM_DIR="/goinfre/${USER}/vms"
DISK="${VM_DIR}/${VM_NAME}.vdi"
ISO_DIR="${VM_DIR}"
# Debian's "current" dir only keeps the latest stable release and its exact point-release
# version changes over time, so discover the real filename instead of hardcoding it.
ISO_INDEX_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/"
ISO_PATH="${ISO_DIR}/debian-netinst.iso"

DISK_SIZE_MB=20480
CPUS=4
MEMORY_MB=4096
SSH_FORWARD_PORT=2222
HOSTNAME="nburchha.42.fr"

mkdir -p "${VM_DIR}"

if [ ! -f "${ISO_PATH}" ]; then
	echo "==> Looking up current Debian netinst ISO..."
	ISO_FILENAME=$(curl -sL --fail "${ISO_INDEX_URL}" | grep -oE 'href="debian-[0-9]+\.[0-9]+\.[0-9]+-amd64-netinst\.iso"' | head -1 | sed -E 's/href="(.*)"/\1/')
	if [ -z "${ISO_FILENAME}" ]; then
		echo "!! Could not find a netinst ISO listed at ${ISO_INDEX_URL}. Check the URL manually." >&2
		exit 1
	fi
	echo "==> Downloading ${ISO_FILENAME}..."
	curl -L --fail -o "${ISO_PATH}" "${ISO_INDEX_URL}${ISO_FILENAME}"
else
	echo "==> ISO already present at ${ISO_PATH}, skipping download."
fi

if VBoxManage list vms | grep -q "\"${VM_NAME}\""; then
	echo "==> VM '${VM_NAME}' already registered. Unregister it first (VBoxManage unregistervm ${VM_NAME} --delete) if you want to recreate it."
	exit 1
fi

echo "==> Creating VM '${VM_NAME}'..."
VBoxManage createvm --name "${VM_NAME}" --ostype Debian13_64 --basefolder "${VM_DIR}" --register

echo "==> Allocating ${DISK_SIZE_MB}MB disk at ${DISK}..."
VBoxManage createmedium disk --filename "${DISK}" --size "${DISK_SIZE_MB}"

echo "==> Configuring CPU/RAM/storage/network..."
VBoxManage modifyvm "${VM_NAME}" \
	--cpus "${CPUS}" \
	--memory "${MEMORY_MB}" \
	--nic1 nat \
	--natpf1 "ssh,tcp,,${SSH_FORWARD_PORT},,22" \
	--graphicscontroller vmsvga \
	--vram 32 \
	--audio-driver none

VBoxManage storagectl "${VM_NAME}" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "${VM_NAME}" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "${DISK}"

read -rsp "Set a password for user '${USER}' inside the VM: " VM_PASSWORD
echo

echo "==> Running unattended install (fully automated, no interaction needed)..."
VBoxManage unattended install "${VM_NAME}" \
	--iso="${ISO_PATH}" \
	--user="${USER}" \
	--password="${VM_PASSWORD}" \
	--full-user-name="${USER}" \
	--hostname="${HOSTNAME}" \
	--install-additions \
	--script-template="${PRESEED}" \
	--start-vm=gui

unset VM_PASSWORD

cat <<EOF

==> A VirtualBox window should have opened showing the install. It will reboot
    on its own when done — just watch it.

    preseed.cfg (see that file for what/why) already takes care of everything:
    ${USER} is in sudo and docker, sshd is installed and enabled, and the
    Inception repo is cloned to ~/Inception. Once you see the login screen,
    log in and it's ready to use — no manual bootstrap step needed:
        ssh -p ${SSH_FORWARD_PORT} ${USER}@localhost
        cd ~/Inception && make
EOF
