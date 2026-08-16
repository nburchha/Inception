#!/usr/bin/env bash
# Tiny assertion framework for tests/checks/*.sh — no external dependencies,
# so it runs unmodified on a bare eval VM.

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FAILURES=()

if [ -t 1 ]; then
	C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
	C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
	C_RED=""; C_GREEN=""; C_YELLOW=""; C_BOLD=""; C_RESET=""
fi

section() {
	echo
	echo "${C_BOLD}== $* ==${C_RESET}"
}

pass() {
	PASS_COUNT=$((PASS_COUNT + 1))
	echo "  ${C_GREEN}PASS${C_RESET}  $*"
}

fail() {
	FAIL_COUNT=$((FAIL_COUNT + 1))
	echo "  ${C_RED}FAIL${C_RESET}  $*"
	FAILURES+=("$*")
}

skip() {
	SKIP_COUNT=$((SKIP_COUNT + 1))
	echo "  ${C_YELLOW}SKIP${C_RESET}  $*"
}

# check "description" <exit-status>
# Usage: some_command; check "description" $?
check() {
	local desc="$1" status="$2"
	if [ "$status" -eq 0 ]; then
		pass "$desc"
	else
		fail "$desc"
	fi
}

# assert_match "description" "haystack" "extended-regex"
assert_match() {
	local desc="$1" haystack="$2" pattern="$3"
	if printf '%s' "$haystack" | grep -Eq "$pattern"; then
		pass "$desc"
	else
		fail "$desc"
	fi
}

# assert_not_match "description" "haystack" "extended-regex"
assert_not_match() {
	local desc="$1" haystack="$2" pattern="$3"
	if printf '%s' "$haystack" | grep -Eq "$pattern"; then
		fail "$desc"
	else
		pass "$desc"
	fi
}

# assert_match_i / assert_not_match_i: case-insensitive variants
assert_match_i() {
	local desc="$1" haystack="$2" pattern="$3"
	if printf '%s' "$haystack" | grep -Eqi "$pattern"; then
		pass "$desc"
	else
		fail "$desc"
	fi
}

assert_not_match_i() {
	local desc="$1" haystack="$2" pattern="$3"
	if printf '%s' "$haystack" | grep -Eqi "$pattern"; then
		fail "$desc"
	else
		pass "$desc"
	fi
}

# assert_file_exists "description" "/path/to/file"
assert_file_exists() {
	local desc="$1" path="$2"
	if [ -f "$path" ]; then
		pass "$desc"
	else
		fail "$desc"
	fi
}

# assert_container_running "container_name"
assert_container_running() {
	local name="$1"
	if [ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)" = "true" ]; then
		pass "container '$name' is running"
	else
		fail "container '$name' is running"
	fi
}

# assert_restart_always "container_name"
assert_restart_always() {
	local name="$1" policy
	policy=$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$name" 2>/dev/null)
	if [ "$policy" = "always" ]; then
		pass "container '$name' has restart policy 'always' (got '$policy')"
	else
		fail "container '$name' has restart policy 'always' (got '${policy:-none}')"
	fi
}

# assert_http_status "description" "url" expected_code [extra curl args...]
assert_http_status() {
	local desc="$1" url="$2" expected="$3"; shift 3
	local actual
	actual=$(curl -sk -o /dev/null -m 8 -w '%{http_code}' "$@" "$url" 2>/dev/null)
	if [ "$actual" = "$expected" ]; then
		pass "$desc (got $actual)"
	else
		fail "$desc (expected $expected, got '${actual:-no response}')"
	fi
}

summary() {
	echo
	echo "${C_BOLD}== Summary ==${C_RESET}"
	echo "  ${C_GREEN}${PASS_COUNT} passed${C_RESET}, ${C_RED}${FAIL_COUNT} failed${C_RESET}, ${C_YELLOW}${SKIP_COUNT} skipped${C_RESET}"
	if [ "$FAIL_COUNT" -gt 0 ]; then
		echo
		echo "${C_RED}Failed checks:${C_RESET}"
		local f
		for f in "${FAILURES[@]}"; do
			echo "  - $f"
		done
		return 1
	fi
	return 0
}
