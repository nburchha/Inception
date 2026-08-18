#!/usr/bin/env bash
# Container / restart-policy / PID1 checks. Requires `make all` to be running.
section "01 -- Containers: up, healthy, restart policy, PID 1"

SERVICES=(nginx wordpress mariadb redis ftp static_site adminer gatus)

docker network ls --format '{{.Name}}' | grep -qx inception
check "docker network 'inception' exists (docker network ls)" $?

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

		# Live counterpart to the static image-name check in 00_static.sh: the
		# actual built/running image must match the service name.
		img="$(docker inspect -f '{{.Config.Image}}' "$svc" 2>/dev/null)"
		assert_match "'$svc' running container's actual image matches its service name" \
			"$img" "^${svc}(:[[:alnum:]._-]+)?\$"

		# Crash-loop detection, approximating "Makefile builds all services via
		# docker compose with no crashes".
		status="$(docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null)"
		assert_not_match "'$svc' is not stuck restarting (state)" "$status" 'restarting'

		restarts="$(docker inspect -f '{{.RestartCount}}' "$svc" 2>/dev/null)"
		if [ "${restarts:-0}" -eq 0 ]; then
			pass "'$svc' has not auto-restarted since it last started (RestartCount=0)"
		else
			fail "'$svc' has not auto-restarted since it last started (RestartCount=${restarts})"
		fi
	else
		skip "'$svc' PID 1 check (container not found)"
	fi
done
