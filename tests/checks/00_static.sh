#!/usr/bin/env bash
# Static checks — pure file/config inspection, no running stack required.
section "00 -- Static: Dockerfiles, compose, secrets"

REQ_DIR="$SRC_DIR/requirements"
SERVICES=(nginx wordpress mariadb redis ftp static_site adminer gatus)

# --- repo structure: config files live under srcs/, Makefile at repo root ---
assert_file_exists "Makefile exists at repo root" "$ROOT_DIR/Makefile"
assert_file_exists "docker-compose.yml exists under srcs/" "$COMPOSE_FILE"

stray="$(find "$ROOT_DIR" -not -path "$ROOT_DIR/.git*" -not -path "$SRC_DIR/*" \
	\( -iname 'Dockerfile' -o -iname 'docker-compose*.yml' -o -iname 'docker-compose*.yaml' \) 2>/dev/null)"
if [ -z "$stray" ]; then
	pass "no stray Dockerfile/docker-compose.yml exists outside srcs/"
else
	fail "no stray Dockerfile/docker-compose.yml exists outside srcs/ (found:$stray)"
fi

# Allowlist of currently-acceptable "penultimate stable" base image tags.
# NOTE: this is a point-in-time judgment call, not a permanent fact -- Debian
# and Alpine release cadence moves. Re-check https://www.debian.org/releases/
# and https://alpinelinux.org/releases/ periodically and update this list;
# don't assume "bookworm" stays correct forever.
ALLOWED_BASE_IMAGES=(
	"debian:bookworm"
	"alpine:3.19" "alpine:3.20" "alpine:3.21" "alpine:3.22" "alpine:3.23"
)

is_allowed_base() {
	local img="$1" allowed
	for allowed in "${ALLOWED_BASE_IMAGES[@]}"; do
		[ "$img" = "$allowed" ] && return 0
	done
	return 1
}

for svc in "${SERVICES[@]}"; do
	df="$REQ_DIR/$svc/Dockerfile"
	assert_file_exists "Dockerfile exists for '$svc'" "$df"
	[ -f "$df" ] || continue

	[ -s "$df" ]
	check "$svc Dockerfile is not empty" $?

	content="$(cat "$df")"
	assert_not_match_i "$svc Dockerfile does not FROM a ':latest' image" "$content" '^\s*FROM\s+\S+:latest'
	assert_not_match "$svc Dockerfile has no infinite-loop / hacky-patch command" "$content" 'tail -f|sleep infinity|while\s*(true|:)'
	assert_not_match_i "$svc Dockerfile has no bare bash/sh as entrypoint" "$content" '(ENTRYPOINT|CMD)\s*\[?\s*"?(/bin/)?(bash|sh)"?\s*\]?\s*$'
	assert_not_match_i "$svc Dockerfile has no hardcoded password literal" "$content" 'password'
	assert_not_match "$svc Dockerfile does not use the legacy '--link' flag" "$content" '[-]-link\b'

	# Base image(s) must be an allowlisted, explicitly-tagged Debian/Alpine --
	# not ":latest" (already checked above) and not a pre-made service image
	# (e.g. FROM wordpress / FROM nginx / FROM node) or an untagged base.
	# Multi-stage-safe: skips FROM references to an earlier internal stage name.
	stage_names=()
	bad_base=""
	while IFS= read -r line; do
		ref="$(printf '%s' "$line" | sed -E 's/^\s*FROM\s+//I')"
		base="$(printf '%s' "$ref" | awk '{print $1}')"
		stage="$(printf '%s' "$ref" | grep -Eio 'AS[[:space:]]+\S+' | awk '{print $2}')"

		is_internal_stage=0
		for s in "${stage_names[@]}"; do
			[ "$base" = "$s" ] && is_internal_stage=1 && break
		done

		if [ "$is_internal_stage" -eq 0 ] && ! is_allowed_base "$base"; then
			bad_base="$bad_base $base"
		fi
		[ -n "$stage" ] && stage_names+=("$stage")
	done < <(grep -Ei '^\s*FROM\s+' "$df")

	if [ -z "$bad_base" ]; then
		pass "$svc Dockerfile FROMs only allowlisted penultimate-stable Debian/Alpine base(s)"
	else
		fail "$svc Dockerfile FROMs a non-allowlisted base image:$bad_base"
	fi

	if [ "$svc" = "wordpress" ] || [ "$svc" = "mariadb" ]; then
		assert_not_match_i "$svc Dockerfile does not install or configure nginx" "$content" 'nginx'
	fi

	# image: in compose must match the service's own name (static config check;
	# see 01_containers.sh for the corresponding live/dynamic check).
	img_line="$(awk -v svc="$svc" '
		$0 ~ "^  "svc":" {infield=1; next}
		infield && /^  [A-Za-z_]/ {infield=0}
		infield && /^\s*image:/ {print; exit}
	' "$COMPOSE_FILE")"
	assert_match "'$svc' compose service declares image: matching its own service name" \
		"$img_line" "image:[[:space:]]*${svc}([:[:alnum:]._-]+)?[[:space:]]*(#.*)?\$"
done

while IFS= read -r -d '' sh; do
	svc="$(basename "$(dirname "$sh")")"
	content="$(cat "$sh")"
	assert_not_match "$svc/script.sh has no infinite-loop pattern" "$content" 'tail -f|sleep infinity|while\s*(true|:)'
	assert_match "$svc/script.sh execs its daemon (PID 1 compliant)" "$content" '^\s*exec\s'
	assert_not_match "$svc/script.sh does not use the legacy '--link' flag" "$content" '[-]-link\b'
	if [ "$svc" = "wordpress" ] || [ "$svc" = "mariadb" ]; then
		assert_not_match_i "$svc/script.sh does not install or run nginx" "$content" 'nginx'
	fi
done < <(find "$REQ_DIR" -name 'script.sh' -print0)

compose="$(cat "$COMPOSE_FILE")"
assert_not_match "docker-compose.yml does not use network: host" "$compose" 'network:\s*host'
assert_not_match "docker-compose.yml does not use legacy 'links:'" "$compose" '^\s*links:'
assert_match "docker-compose.yml defines a networks: section" "$compose" '^\s*networks:'
assert_not_match "docker-compose.yml does not use the legacy '--link' flag" "$compose" '[-]-link\b'

overrides="$(grep -E '^\s*(command|entrypoint):' "$COMPOSE_FILE")"
if [ -n "$overrides" ]; then
	assert_not_match "docker-compose.yml command/entrypoint overrides have no infinite-loop pattern" \
		"$overrides" 'tail -f|sleep infinity|while\s*(true|:)'
else
	skip "docker-compose.yml command/entrypoint override scan (no overrides present)"
fi

if [ -f "$ROOT_DIR/Makefile" ]; then
	assert_not_match "Makefile does not use the legacy '--link' flag" "$(cat "$ROOT_DIR/Makefile")" '[-]-link\b'
fi

for vol in web database; do
	block="$(grep -A4 "^  $vol:" "$COMPOSE_FILE")"
	assert_match "'$vol' volume uses driver_opts (named volume, not an inline bind mount)" "$block" 'driver_opts'
done

if git -C "$ROOT_DIR" check-ignore -q "$SRC_DIR/.env" 2>/dev/null; then
	pass ".env is git-ignored"
else
	fail ".env is git-ignored"
fi
