#!/bin/bash
#
# Creates a Git tag to mark successful deployment with fa-harness-tools
#
# Optionally set ONLY_ENVIRONMENT to only tag when running a deployment in
# that Harness environment.

set -e

export GITHUB_OAUTH_TOKEN="${secrets.getValue("github-oauth-token")}"

if [ -z "${ONLY_ENVIRONMENT}" -o "${ONLY_ENVIRONMENT}" = "${env.name}" ]; then
  create-deployment-tag \
    --build-no "${artifact.buildNo}" \
    --environment "${env.name}" \
    --repository "${artifact.source.repositoryName}" \
    --tagger-email "noreply@example.com" \
    --tagger-name "Harness"
fi
