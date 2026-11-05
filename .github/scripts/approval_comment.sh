#!/usr/bin/env bash
# Print the comment the reviewer left when approving the given environment for
# this run, or nothing if there is none. Reads the run's review history:
# https://docs.github.com/en/rest/actions/workflow-runs#get-the-review-history-for-a-workflow-run
# Needs GH_TOKEN with `actions: read`, and GITHUB_REPOSITORY and GITHUB_RUN_ID
# as set on every runner.
set -euo pipefail

environment="$1"

gh api "repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/approvals" \
    | jq -r --arg env "${environment}" '
        [ .[] | select(.state == "approved" and any(.environments[]; .name == $env)) ]
        | first // {} | .comment // ""'
