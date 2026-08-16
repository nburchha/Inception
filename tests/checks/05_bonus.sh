#!/usr/bin/env bash
# Bonus services: redis cache, ftp, adminer, static_site, gatus.
section "05 -- Bonus: redis, ftp, adminer, static_site, gatus"

TARGET="${DOMAIN:-localhost}"

# --- redis: object cache active for WordPress ---
if docker inspect wordpress >/dev/null 2>&1 && [ "$(docker inspect -f '{{.State.Running}}' wordpress 2>/dev/null)" = "true" ]; then
	if docker exec wordpress test -f /var/www/html/wp-content/object-cache.php 2>/dev/null; then
		pass "redis object-cache.php is installed in the WordPress volume"
	else
		fail "redis object-cache.php is installed in the WordPress volume"
	fi
else
	skip "redis object-cache check (wordpress container not running)"
fi

if docker exec redis redis-cli ping 2>/dev/null | grep -q PONG; then
	pass "redis responds to PING"
else
	fail "redis responds to PING"
fi

# --- ftp: reachable and serves the same files as the web volume ---
if command -v curl >/dev/null 2>&1; then
	ftp_user="${FTP_USER:-ftpuser}"
	ftp_pass="${FTP_PASSWORD:-ftppassword}"
	listing="$(curl -s -m 8 --user "${ftp_user}:${ftp_pass}" "ftp://${TARGET}/" 2>/dev/null)"
	assert_match "FTP login + listing works and shows WordPress files" "$listing" 'wp-config\.php|wp-content|wp-admin'
else
	skip "FTP check (curl not installed)"
fi

# --- adminer: reachable ---
assert_http_status "Adminer responds on :8080" "http://localhost:8080/" 200

# --- static_site: reachable through nginx, not PHP-rendered ---
static_body="$(curl -sk -m 8 "https://${TARGET}/static/" 2>/dev/null)"
assert_not_match_i "static site is not PHP (no PHP notice/tags leaking through)" "$static_body" '<\?php|Fatal error:'
assert_http_status "static site reachable via nginx /static/" "https://${TARGET}/static/" 200

# --- gatus: reachable, monitoring the other services ---
assert_http_status "gatus dashboard reachable via nginx" "https://gatus.${TARGET}/" 200
