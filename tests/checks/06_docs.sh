#!/usr/bin/env bash
# README.md / USER_DOC.md / DEV_DOC.md presence and required content.
section "06 -- Docs: README, USER_DOC.md, DEV_DOC.md"

README="$ROOT_DIR/README.md"
USER_DOC="$ROOT_DIR/USER_DOC.md"
DEV_DOC="$ROOT_DIR/DEV_DOC.md"

assert_file_exists "README.md exists at repo root" "$README"
if [ -f "$README" ]; then
	first_line="$(head -n1 "$README")"
	assert_match "README first line is the required italicized attribution sentence" \
		"$first_line" '^\*This project has been created as part of the 42 curriculum by [^*]+\.\*$'

	readme="$(cat "$README")"
	assert_match "README has a Description section" "$readme" '^#+ *Description'
	assert_match "README has an Instructions section" "$readme" '^#+ *Instructions'
	assert_match "README has a Resources section" "$readme" '^#+ *Resources'
	assert_match_i "README Resources section documents AI usage" "$readme" 'AI (was )?used|AI usage'
	assert_match_i "README compares VMs vs Docker" "$readme" 'virtual machine.*docker|docker.*virtual machine'
	assert_match_i "README compares Secrets vs Environment Variables" "$readme" 'secrets.*environment variable'
	assert_match_i "README compares Docker Network vs Host Network" "$readme" 'docker network.*host network'
	assert_match_i "README compares Docker Volumes vs Bind Mounts" "$readme" 'volumes.*bind mount'
	assert_match_i "README justifies the custom bonus service 'gatus' by name" "$readme" 'gatus'
fi

assert_file_exists "USER_DOC.md exists at repo root" "$USER_DOC"
if [ -f "$USER_DOC" ]; then
	doc="$(cat "$USER_DOC")"
	assert_match_i "USER_DOC.md explains starting/stopping the project" "$doc" 'stop|start'
	assert_match_i "USER_DOC.md explains accessing the site/admin panel" "$doc" 'wp-admin|admin panel'
	assert_match_i "USER_DOC.md explains locating/managing credentials" "$doc" 'credential|\.env'
	assert_match_i "USER_DOC.md explains checking services are running" "$doc" 'status|running correctly'
fi

assert_file_exists "DEV_DOC.md exists at repo root" "$DEV_DOC"
if [ -f "$DEV_DOC" ]; then
	doc="$(cat "$DEV_DOC")"
	assert_match_i "DEV_DOC.md covers environment setup (prerequisites/secrets)" "$doc" 'prerequisite|\.env'
	assert_match_i "DEV_DOC.md covers building/launching via Makefile+Compose" "$doc" 'makefile|docker compose'
	assert_match_i "DEV_DOC.md covers container/volume management commands" "$doc" 'docker (exec|logs|volume)'
	assert_match_i "DEV_DOC.md identifies where data is stored/persists" "$doc" 'persist|data.*stored|/home/'
fi
