# Production pre-flight checks

## Purpose

Can be added to a Harness pipeline to enforce a set of strict requirements for production deployments:

1. Only deploy within the daily deployment window/schedule
2. Only deploy builds from the master branch
3. Automated (triggered) deployments may only deploy forwards
4. Manual deployments may only deploy forwards or roll back three deployments

## Requirements

1. Add a GitHub OAuth token to the Harness secrets manager, named `github-oauth-token`
2. Assumes the artifact build number is the commit ID
3. fa-harness-tools is installed on the Harness delegates (`gem install -v $VERSION fa-harness-tools`)

## Installation

Add the script to the Harness template library and then add to an early phase of the deployment workflow.
