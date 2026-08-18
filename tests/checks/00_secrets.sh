#!/usr/bin/env bash
# Secret-leak scan — the eval's "credentials/API keys committed to git outside
# secrets = automatic 0" rule. Always runs (not bonus- or --full-gated): a
# leaked credential is disqualifying regardless of mode.
section "00 -- Secrets: no committed credential values"

# Only git-tracked files are searched (git grep's default), so the git-ignored
# srcs/.env itself is correctly out of scope -- its ignored status is already
# asserted in 00_static.sh -- and the blank env_default.txt template can never
# false-positive since its values are empty.
SECRET_VARS=(WP_DB_PASSWORD WP_ADMIN_PASSWORD WP_USER_PASSWORD FTP_PASSWORD)

for var in "${SECRET_VARS[@]}"; do
	val="${!var:-}"
	# Skip unset/empty (env not sourced) and trivially short values, which
	# would produce noisy false positives against ordinary prose/code.
	if [ -z "$val" ] || [ "${#val}" -lt 6 ]; then
		skip "secret-leak scan for \$$var (unset, or too short to check safely)"
		continue
	fi
	if git -C "$ROOT_DIR" grep -qF -- "$val" -- . 2>/dev/null; then
		fail "no git-tracked file contains the literal value of \$$var"
	else
		pass "no git-tracked file contains the literal value of \$$var"
	fi
done

# Generic credential-shaped patterns, independent of the local .env values --
# catches secrets a reviewer/learner might paste in from elsewhere.
if git -C "$ROOT_DIR" grep -qEi -- '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----' 2>/dev/null; then
	fail "no git-tracked file contains an embedded private key"
else
	pass "no git-tracked file contains an embedded private key"
fi

if git -C "$ROOT_DIR" grep -qE -- 'AKIA[0-9A-Z]{16}' 2>/dev/null; then
	fail "no git-tracked file contains an AWS-access-key-shaped string"
else
	pass "no git-tracked file contains an AWS-access-key-shaped string"
fi
