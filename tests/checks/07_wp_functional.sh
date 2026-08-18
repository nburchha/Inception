#!/usr/bin/env bash
# Functional WordPress checks — only run with --full, since these write real
# content into the live site. Covers the eval's "can add a comment as a WP
# user" and "page edits from the dashboard are visible on the site" checks,
# which nothing else in this suite exercises end-to-end.
section "07 -- WordPress functional: comment creation, page-edit visibility"

WP="docker exec wordpress wp --allow-root --path=/var/www/html"

ensure_wp_cli() {
	docker exec wordpress test -x /usr/local/bin/wp 2>/dev/null && return 0
	docker exec wordpress bash -c \
		'curl -sSfo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /usr/local/bin/wp' \
		>/dev/null 2>&1
}

if [ "$(docker inspect -f '{{.State.Running}}' wordpress 2>/dev/null)" != "true" ]; then
	skip "WordPress functional checks (wordpress container not running)"
	return 0 2>/dev/null || exit 0
fi

# wp-cli is only installed on first boot inside script.sh's wp-config.php-missing
# guard; on any later container recreate the (ephemeral) container filesystem
# won't have it even though the volume-backed WP install persists. Self-heal.
if ! ensure_wp_cli; then
	skip "WordPress functional checks (wp-cli unavailable and could not be installed)"
	return 0 2>/dev/null || exit 0
fi

# --- A. comment creation as a WP user ---
CANARY_TAG="__inception_test_comment__"

old_ids="$($WP comment list --search="$CANARY_TAG" --field=ID --format=csv 2>/dev/null)"
for id in $old_ids; do $WP comment delete "$id" --force >/dev/null 2>&1; done

post_id="$($WP post list --post_type=post --post_status=publish --posts_per_page=1 \
	--field=ID --format=csv 2>/dev/null | head -n1)"

if [ -z "$post_id" ]; then
	skip "WP comment-as-user check (no published post found to comment on)"
else
	unique="${CANARY_TAG}-$(date +%s)"
	comment_id="$($WP comment create \
		--comment_post_ID="$post_id" \
		--comment_author="${WP_USER:-tester}" \
		--comment_author_email="${WP_USER_EMAIL:-tester@example.com}" \
		--comment_content="$unique" \
		--comment_approved=1 \
		--porcelain 2>/dev/null)"

	if [ -n "$comment_id" ]; then
		pass "wp-cli comment create succeeded as WP user (id=$comment_id)"
		post_url="$($WP post list --include="$post_id" --field=url --format=csv 2>/dev/null | head -n1)"
		body="$(curl -sk -m 8 "$post_url" 2>/dev/null)"
		assert_match "created comment is visible on the live front-end page" "$body" "$unique"
		$WP comment delete "$comment_id" --force >/dev/null 2>&1
		check "test comment cleaned up after assertion" $?
	else
		fail "wp-cli comment create succeeded as WP user"
	fi
fi

# --- B. page edit visibility ---
PAGE_TITLE="Inception Test Page (automated check)"

old_page_id="$($WP post list --post_type=page --title="$PAGE_TITLE" --field=ID --format=csv 2>/dev/null | head -n1)"
[ -n "$old_page_id" ] && $WP post delete "$old_page_id" --force >/dev/null 2>&1

marker1="edit-canary-initial-$(date +%s)"
page_id="$($WP post create --post_type=page --post_title="$PAGE_TITLE" \
	--post_status=publish --post_content="$marker1" --porcelain 2>/dev/null)"

if [ -n "$page_id" ]; then
	pass "wp-cli page create succeeded (id=$page_id)"
	page_url="$($WP post list --include="$page_id" --field=url --format=csv 2>/dev/null | head -n1)"

	body1="$(curl -sk -m 8 "$page_url" 2>/dev/null)"
	assert_match "initial page content is visible on the live site" "$body1" "$marker1"

	# simulate a dashboard edit
	marker2="edit-canary-updated-$(date +%s)"
	$WP post update "$page_id" --post_content="$marker2" >/dev/null 2>&1
	sleep 1
	body2="$(curl -sk -m 8 "$page_url" 2>/dev/null)"
	assert_match "page edit is visible on the live site (dashboard-edit propagation)" "$body2" "$marker2"

	$WP post delete "$page_id" --force >/dev/null 2>&1
	check "test page cleaned up after assertion" $?
else
	fail "wp-cli page create succeeded"
fi
