module FaHarnessTools
  # CheckRecentDeploy only allows deployer to deploy commits with `deploy_tag_prefix` ahead of (and include) Nth most recent commit
  # with the give tag.
  #
  # For example if the commit history is like
  #
  # SHA 1
  # SHA 2 - tag: production-deploy-1
  # SHA 3
  # SHA 4 - tag: production-deploy-2
  # SHA 5
  # SHA 6 - tag: production-deploy-3
  # SHA 7
  # SHA 8 - tag: production-deploy-4
  #
  # If the age deploy check is set to
  #   tag_prefix: "production-deploy"
  #   allowed_rollback_count: 2
  #
  # Then SHA 1 - 4 would be allowed, however SHA 5 - 8 would get denied
  #
  # Notes if the tag `production-deploy-` doesn't exist in Git history, the check returns allow
  #
  class CheckRecentDeploy
    def initialize(client:, context:, tag_prefix:, new_sha:, allowed_rollback_count:)
      @client = client
      @context = context
      @tag_prefix = tag_prefix
      @new_sha = new_sha
      @allowed_rollback_count = allowed_rollback_count
      @logger = CheckLogger.new(
        name: "Check recent deploys",
        description: "Only allow deployments of recent commits, up to #{@allowed_rollback_count} deployment rollbacks",
      )
    end

    def verify?
      @logger.start
      @logger.context_info(@client, @context, @new_sha)

      tags = @client.
        all_deploy_tags(prefix: @tag_prefix, environment: @context.environment).
        sort_by { |tag| tag[:name] }

      latest_allowed_tag = tags.last(@allowed_rollback_count).first

      if latest_allowed_tag.nil?
        # If no previous deploys we need to let it deploy otherwise it will
        # never get past this check!
        @logger.info "no #{@tag_prefix} tag was found, so this must be the first deployment"
        return @logger.pass("this is the first recorded deployment so is permitted")
      end

      @logger.info("the most recent tag allowed is #{latest_allowed_tag[:name]}")

      latest_allowed_rev = @client.get_commit_sha_from_tag(latest_allowed_tag)
      @logger.info("which means the most recent commit allowed is #{latest_allowed_rev}")

      if @client.is_ancestor_of?(latest_allowed_rev, @new_sha)
        @logger.pass "the commit being deployed is more recent than the last permitted rollback commit"
      else
        @logger.fail "the commit being deployed is older than the last permitted rollback commit"
      end
    end
  end
end
