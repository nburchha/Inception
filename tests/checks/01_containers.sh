#!/usr/bin/env bash
# Container / restart-policy / PID1 checks. Requires `make all` to be running.
section "01 -- Containers: up, healthy, restart policy, PID 1"

SERVICES=(nginx wordpress mariadb redis ftp static_site adminer gatus)

# expected foreground process per service, for the PID1 sanity check
# (bash 3.2 on macOS has no associative arrays, so a case statement it is)
expect_cmd() {
	case "$1" in
	nginx) echo "nginx" ;;
	wordpress) echo "php-fpm" ;;
	mariadb) echo "mysqld" ;;
	redis) echo "redis-server" ;;
	ftp) echo "vsftpd" ;;
	static_site) echo "node" ;;
	adminer) echo "php" ;;
	gatus) echo "gatus" ;;
	esac
}

for svc in "${SERVICES[@]}"; do
	assert_container_running "$svc"
	assert_restart_always "$svc"

	if docker inspect "$svc" >/dev/null 2>&1; then
		top="$(docker top "$svc" 2>/dev/null | tail -n +2)"
		expected="$(expect_cmd "$svc")"
		assert_match "'$svc' PID 1 runs its real daemon ('$expected'), not a shell wrapper" \
			"$top" "$expected"
		assert_not_match "'$svc' PID 1 is not tail/sleep/bash-infinite-loop" \
			"$top" 'tail -f|sleep infinity|while (true|:)'
	else
		skip "'$svc' PID 1 check (container not found)"
	fi
done
