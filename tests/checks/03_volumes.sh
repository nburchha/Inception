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

# Generic "database not empty" check (schema-agnostic -- distinct from
# 04_wordpress.sh's WP-specific wp_users count).
if [ "$(docker inspect -f '{{.State.Running}}' mariadb 2>/dev/null)" = "true" ]; then
	table_count="$(docker exec mariadb mysql -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" "${WP_DB_NAME}" \
		-N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE();" 2>/dev/null)"

	if [ "${table_count:-0}" -ge 1 ] 2>/dev/null; then
		pass "MariaDB database '${WP_DB_NAME}' is not empty (has ${table_count} table(s))"
	else
		fail "MariaDB database '${WP_DB_NAME}' is not empty (has ${table_count:-0} table(s))"
	fi
else
	skip "MariaDB non-empty check (mariadb container not running)"
fi
