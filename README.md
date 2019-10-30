# fa-harness-tools

FreeAgent-specific pre-flight checks and tools that are designed to work in [Harness](https://harness.io).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fa-harness-tools'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fa-harness-tools

## Usage

Examples below use [variables defined by Harness](https://docs.harness.io/article/9dvxcegm90-variables) so should be suitable to use directly in Harness scripts.

### Required environment variables

* `GITHUB_OAUTH_TOKEN` must be exported, containing a valid [personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) for GitHub

### check-branch-brotection

Check the new build/commit being deployed is on the master branch:

```
bundle exec exe/check-branch-protection -r ${artifact.source.repositoryName} -e ${env.name} -b ${artifact.buildNo}
```

(Branch name etc can be changed, see `--help` for more options.)

### check-forward-deploy

Using a Git tag indicating the last deployment, check that the new commit being deployed is a descendant of the current commit:

```
bundle exec exe/check-forward-deploy -r ${artifact.source.repositoryName} -e ${env.name} -b ${artifact.buildNo}
```

(Tag prefix etc can be changed, see `--help` for more options.)

### check-recent-deploy

Using Git tags indicating recent deployments, check the commit being deployed is one of the last X commits or newer. Allows a user to rollback by X deployments.

```
bundle exec exe/check-recent-deploy -r ${artifact.source.repositoryName} -e ${env.name} -b ${artifact.buildNo}
```

(Allowed rollback count and tag prefix etc can be changed, see `--help` for more options.)

### check-schedule

Check the current time is within the deployment window of Mon-Thu 9am to 4pm, or Fri 9am to 12pm, using local London time.

```
bundle exec exe/check-schedule
```

### create-deployment-tag

Creates a Git tag in the project repository to indicate the deployment has happened:

```
bundle exec exe/create-deployment-tag -r ${artifact.source.repositoryName} -e ${env.name} -b ${artifact.buildNo}
```

(Tagger's name and email address etc can be changed, see `--help` for more options.)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

The Ruby version used matches the one from the `harness/delegate` Docker image.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fac/fa-harness-tools

## Licence

Copyright 2019 FreeAgent Central Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
