#!/usr/bin/env bash
# Disruptive checks — only run with --full. These intentionally interrupt
# running containers, so don't run them against a stack you care about right now.
section "99 -- Disruptive: crash-restart, down/up persistence"

# --- crash-restart ---
# NOTE: `docker kill`/`docker stop` are deliberately EXCLUDED from `restart: always`
# by dockerd itself (verified empirically: after `docker kill`, RestartCount stays 0
# and the container sits Exited indefinitely) — Docker treats a CLI-issued kill/stop
# as an intentional stop, not a crash, and this is true on any Docker host, not just
# this machine. Sending SIGKILL to PID 1 *from inside* the container doesn't work
# either: the kernel's PID-namespace-init immunity makes a namespace's PID 1 ignore
# unhandled signals (including SIGKILL) sent from within its own namespace — only a
# signal from an ancestor (host) namespace bypasses that, which the Docker CLI's own
# kill/stop path explicitly avoids applying to the restart supervisor.
# So there's no portable, non-destructive way to fake "a crash" here; the actual
# guarantee (`restart: always` is configured) is already verified statically in
# 01_containers.sh via `docker inspect`, which is what the subject requirement
# actually depends on — real crash recovery is best spot-checked live if needed
# (kill the daemon process from the real Linux host outside of Docker's CLI, or an
# OOM) rather than baked into this suite as a reliable automated check.
skip "crash-restart (docker kill/stop are treated as intentional stops by dockerd and never trigger restart:always -- see 01_containers.sh for the static policy check instead)"

# --- persistence: record WP option count, cycle the stack, confirm it survives ---
if [ "$(docker inspect -f '{{.State.Running}}' mariadb 2>/dev/null)" = "true" ]; then
	before="$(docker exec mariadb mysql -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" "${WP_DB_NAME}" \
		-N -e "SELECT COUNT(*) FROM wp_options;" 2>/dev/null)"

	docker compose -f "$COMPOSE_FILE" down >/dev/null 2>&1
	docker compose -f "$COMPOSE_FILE" up -d >/dev/null 2>&1

	for _ in $(seq 1 30); do
		[ "$(docker inspect -f '{{.State.Running}}' mariadb 2>/dev/null)" = "true" ] && break
		sleep 2
	done
	sleep 5

	after="$(docker exec mariadb mysql -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" "${WP_DB_NAME}" \
		-N -e "SELECT COUNT(*) FROM wp_options;" 2>/dev/null)"

	if [ -n "$before" ] && [ "$before" = "$after" ]; then
		pass "wp_options row count survives a compose down/up cycle ($before rows)"
	else
		fail "wp_options row count survives a compose down/up cycle (before=$before, after=$after)"
	fi

	# --- config-modification approximation ---
	# Reuses the down/up cycle above rather than mutating the stack a second
	# time. This approximates the eval's live "reviewer requests a config
	# change, learner rebuilds/restarts" exercise, which is otherwise an
	# inherently manual, reviewer-driven step -- it only proves the mechanics
	# (down/up -> all services up, site reachable) hold, not that any specific
	# requested change was correctly applied.
	SERVICES=(nginx wordpress mariadb redis ftp static_site adminer gatus)
	all_up=1
	for svc in "${SERVICES[@]}"; do
		[ "$(docker inspect -f '{{.State.Running}}' "$svc" 2>/dev/null)" = "true" ] || all_up=0
	done
	if [ "$all_up" -eq 1 ]; then
		pass "all 8 services are running again after a down/up (rebuild-style) cycle"
	else
		fail "all 8 services are running again after a down/up (rebuild-style) cycle"
	fi

	reachable=0
	for _ in $(seq 1 30); do
		code="$(curl -sk -o /dev/null -m 5 -w '%{http_code}' "https://${DOMAIN:-localhost}/" 2>/dev/null)"
		[ "$code" = "200" ] && { reachable=1; break; }
		sleep 2
	done
	if [ "$reachable" -eq 1 ]; then
		pass "WordPress is reachable over HTTPS after the down/up cycle"
	else
		fail "WordPress is reachable over HTTPS after the down/up cycle"
	fi
else
	skip "persistence check (mariadb not running)"
	skip "config-modification approximation (mariadb not running)"
fi
