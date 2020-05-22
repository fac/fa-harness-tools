#!/bin/bash
#
# Runs production deployment checks from fa-harness-tools

set -e

export GITHUB_OAUTH_TOKEN="${secrets.getValue("github-oauth-token")}"

run() {
  CMD=$1
  shift
  echo
  $CMD \
    --build-no "${artifact.buildNo}" \
    --environment "${env.name}" \
    --repository "${artifact.source.repositoryName}" \
    "$@"
  echo
}

# 1. Check we're within the daily deployment schedule
check-schedule

# 2. Check the commit is on the master branch
run check-branch-protection

if [[ "${deploymentTriggeredBy}" =~ "Deployment Trigger" ]]; then
  # 3. For automated deployments (trigger from CI), check deployment is fast-forward
  run check-forward-deploy
else
  # 3. For user deployments, check deployment is fast-forward or within last three deployments for rollbacks
  run check-recent-deploy --allowed-rollback-count 3
fi

exit 0
