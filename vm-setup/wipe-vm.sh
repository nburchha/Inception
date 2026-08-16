#!/bin/bash
# Destroys the Inception VM: powers it off, unregisters it, and deletes its disk
# and settings folder from /goinfre. The downloaded Debian ISO is left in place
# (reusable) so create-vm.sh doesn't have to re-download it.
set -euo pipefail

VM_NAME="inception"

if ! VBoxManage list vms | grep -q "\"${VM_NAME}\""; then
	echo "==> VM '${VM_NAME}' is not registered, nothing to wipe."
	exit 0
fi

read -rp "This will permanently delete the '${VM_NAME}' VM and everything on its disk (WordPress data, DB, etc.). Continue? [y/N] " CONFIRM
if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
	echo "Aborted."
	exit 1
fi

if VBoxManage list runningvms | grep -q "\"${VM_NAME}\""; then
	echo "==> Powering off '${VM_NAME}'..."
	VBoxManage controlvm "${VM_NAME}" poweroff
	# give it a moment to fully release the disk before we delete it
	sleep 2
fi

echo "==> Unregistering and deleting '${VM_NAME}' (disk + settings)..."
VBoxManage unregistervm "${VM_NAME}" --delete

echo "==> Done. Run ./create-vm.sh to rebuild it (ISO is cached, so this is fast)."
