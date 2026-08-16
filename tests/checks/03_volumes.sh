#!/usr/bin/env bash
# Named volumes must exist and live under /home/<login>/data on the host.
section "03 -- Volumes: named, host path under /home/<login>/data"

VOLUMES=(web database gatus_data)

for vol in "${VOLUMES[@]}"; do
	if docker volume inspect "$vol" >/dev/null 2>&1; then
		pass "docker volume '$vol' exists"
	else
		fail "docker volume '$vol' exists"
		continue
	fi

	driver="$(docker volume inspect -f '{{.Driver}}' "$vol")"
	assert_match "'$vol' is a local named volume (not a raw bind mount)" "$driver" '^local$'

	device="$(docker volume inspect -f '{{index .Options "device"}}' "$vol" 2>/dev/null)"
	assert_match "'$vol' host path is under /home/<login>/data (got '${device:-unset}')" "$device" '^/home/[^/]+/data/'
done
