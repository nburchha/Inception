#!/usr/bin/env bash
# Automated requirement-checker for the Inception subject.
# Usage: tests/run.sh [--full|--disruptive] [--mandatory-only]
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/srcs"
COMPOSE_FILE="$SRC_DIR/docker-compose.yml"
cd "$ROOT_DIR"

if [ -f "$SRC_DIR/.env" ]; then
	set -a
	# shellcheck disable=SC1090,SC1091
	source "$SRC_DIR/.env"
	set +a
fi

FULL=0
MANDATORY_ONLY=0
for arg in "$@"; do
	case "$arg" in
	--full | --disruptive) FULL=1 ;;
	--mandatory-only) MANDATORY_ONLY=1 ;;
	-h | --help)
		echo "Usage: $0 [--full|--disruptive] [--mandatory-only]"
		echo "  --full / --disruptive  also run crash-restart + down/up persistence checks"
		echo "  --mandatory-only       skip bonus-service checks"
		exit 0
		;;
	*)
		echo "Unknown option: $arg" >&2
		exit 2
		;;
	esac
done

export ROOT_DIR SRC_DIR COMPOSE_FILE

# shellcheck disable=SC1091
source "$ROOT_DIR/tests/lib/assert.sh"

# Check files are picked up by naming convention, sorted, so new categories
# just need to be dropped into tests/checks/ without touching this runner.
# 05_bonus.sh is skippable via --mandatory-only; 99_disruptive.sh only runs
# with --full/--disruptive; everything else always runs.
for f in "$ROOT_DIR"/tests/checks/*.sh; do
	base="$(basename "$f")"
	case "$base" in
	05_bonus.sh)
		[ "$MANDATORY_ONLY" -eq 1 ] && continue
		;;
	99_disruptive.sh)
		[ "$FULL" -eq 0 ] && continue
		;;
	esac
	# shellcheck disable=SC1090
	source "$f"
done

summary
exit $?
