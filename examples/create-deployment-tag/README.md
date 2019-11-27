# Create deployment Git tags

## Purpose

Can be added to a Harness pipeline to add a Git tag on every deployment. The tags can then be used by the other pre-flight checks.

## Requirements

1. Add a GitHub OAuth token to the Harness secrets manager, named `github-oauth-token`
2. Assumes the artifact build number is the commit ID
3. fa-harness-tools is installed on the Harness delegates (`gem install -v $VERSION fa-harness-tools`)

## Installation

Add the script to the Harness template library and then add to the last phase of the deployment workflow.

Define the `ONLY_ENVIRONMENT` variable input on the template, defaulting to `false`.
