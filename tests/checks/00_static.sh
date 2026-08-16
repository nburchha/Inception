#!/usr/bin/env bash
# Static checks — pure file/config inspection, no running stack required.
section "00 -- Static: Dockerfiles, compose, secrets"

REQ_DIR="$SRC_DIR/requirements"
SERVICES=(nginx wordpress mariadb redis ftp static_site adminer gatus)

for svc in "${SERVICES[@]}"; do
	df="$REQ_DIR/$svc/Dockerfile"
	assert_file_exists "Dockerfile exists for '$svc'" "$df"
	[ -f "$df" ] || continue

	content="$(cat "$df")"
	assert_not_match_i "$svc Dockerfile does not FROM a ':latest' image" "$content" '^\s*FROM\s+\S+:latest'
	assert_not_match "$svc Dockerfile has no infinite-loop / hacky-patch command" "$content" 'tail -f|sleep infinity|while\s*(true|:)'
	assert_not_match_i "$svc Dockerfile has no bare bash/sh as entrypoint" "$content" '(ENTRYPOINT|CMD)\s*\[?\s*"?(/bin/)?(bash|sh)"?\s*\]?\s*$'
	assert_not_match_i "$svc Dockerfile has no hardcoded password literal" "$content" 'password'
done

while IFS= read -r -d '' sh; do
	svc="$(basename "$(dirname "$sh")")"
	content="$(cat "$sh")"
	assert_not_match "$svc/script.sh has no infinite-loop pattern" "$content" 'tail -f|sleep infinity|while\s*(true|:)'
	assert_match "$svc/script.sh execs its daemon (PID 1 compliant)" "$content" '^\s*exec\s'
done < <(find "$REQ_DIR" -name 'script.sh' -print0)

compose="$(cat "$COMPOSE_FILE")"
assert_not_match "docker-compose.yml does not use network: host" "$compose" 'network:\s*host'
assert_not_match "docker-compose.yml does not use legacy 'links:'" "$compose" '^\s*links:'
assert_match "docker-compose.yml defines a networks: section" "$compose" '^\s*networks:'

for vol in web database; do
	block="$(grep -A4 "^  $vol:" "$COMPOSE_FILE")"
	assert_match "'$vol' volume uses driver_opts (named volume, not an inline bind mount)" "$block" 'driver_opts'
done

if git -C "$ROOT_DIR" check-ignore -q "$SRC_DIR/.env" 2>/dev/null; then
	pass ".env is git-ignored"
else
	fail ".env is git-ignored"
fi
