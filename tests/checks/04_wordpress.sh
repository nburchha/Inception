#!/usr/bin/env bash
# WordPress DB content rules: >=2 users, admin's login must not contain
# admin/Admin/administrator/Administrator as a substring (e.g. admin-123 fails too).
section "04 -- WordPress: DB users, admin naming rule"

BAD_ADMIN_RE='admin|administrator'

assert_not_match_i "WP_ADMIN_USER in .env does not contain admin/administrator" "${WP_ADMIN_USER:-}" "$BAD_ADMIN_RE"

if docker inspect mariadb >/dev/null 2>&1 && [ "$(docker inspect -f '{{.State.Running}}' mariadb 2>/dev/null)" = "true" ]; then
	logins="$(docker exec mariadb mysql -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" "${WP_DB_NAME}" \
		-N -e "SELECT user_login FROM wp_users;" 2>/dev/null)"

	count="$(printf '%s\n' "$logins" | grep -c . || true)"
	if [ "$count" -ge 2 ]; then
		pass "wp_users has at least 2 accounts (found $count)"
	else
		fail "wp_users has at least 2 accounts (found $count)"
	fi

	if printf '%s\n' "$logins" | grep -Eqi "$BAD_ADMIN_RE"; then
		fail "no wp_users login contains admin/administrator (found: $(printf '%s' "$logins" | tr '\n' ' '))"
	else
		pass "no wp_users login contains admin/administrator"
	fi
else
	skip "wp_users DB checks (mariadb container not running)"
fi
