#!/usr/bin/env bash
# NGINX must be the only entrypoint, on 443, TLSv1.2/1.3 only.
section "02 -- Network & TLS: only 443 exposed, TLSv1.2/1.3 only"

TARGET="${DOMAIN:-localhost}"

# port 80 must not be reachable at all (nginx only listens on 443)
if curl -sk -o /dev/null -m 5 "http://${TARGET}:80/" 2>/dev/null; then
	fail "port 80 is not reachable (nginx must be TLS-only on 443)"
else
	pass "port 80 is not reachable (nginx must be TLS-only on 443)"
fi

if command -v openssl >/dev/null 2>&1; then
	if echo | openssl s_client -connect "${TARGET}:443" -tls1_1 >/dev/null 2>&1; then
		fail "TLSv1.1 handshake is rejected"
	else
		pass "TLSv1.1 handshake is rejected"
	fi

	for ver in tls1_2 tls1_3; do
		label="TLSv1.${ver##*_}"
		if echo | openssl s_client -connect "${TARGET}:443" -"${ver}" >/dev/null 2>&1; then
			pass "$label handshake succeeds"
		else
			fail "$label handshake succeeds"
		fi
	done
else
	skip "TLS protocol checks (openssl not installed)"
fi

assert_http_status "WordPress site responds over HTTPS" "https://${TARGET}/" 200

body="$(curl -sk -m 8 "https://${TARGET}/" 2>/dev/null)"
assert_not_match "WordPress shows the real site, not the install wizard" "$body" 'wp-admin/setup-config\.php|wp-admin/install\.php'
