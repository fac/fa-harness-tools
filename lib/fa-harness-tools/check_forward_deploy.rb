module FaHarnessTools
  # Checks if the revision to deploy is ahead of the deployed revision,  a
  # forward deploy. The currently deployed revision is an ancestor of the
  # revision to deploy.
  #
  # In order to work out what is currently deployed it checks for tags with
  # the configured tag_prefix, the newest of those is considered the current
  # version.
  # If there are none of those tags at all it will allow, to avoid creating an
  # un-passable check!
  class CheckForwardDeploy
    def initialize(client:, context:, tag_prefix:, new_sha:)
      @client = client
      @context = context
      @tag_prefix = tag_prefix
      @new_sha = new_sha
      @logger = CheckLogger.new(
        name: "Check forward deploy",
        description: "Only allow deployments that are newer than what's currently deployed",
      )
    end

    def verify?
      @logger.start
      @logger.context_info(@client, @context, @new_sha)

      current_tag = @client.last_deploy_tag(
        prefix: @tag_prefix, environment: @context.environment,
      )

      if current_tag.nil?
        # If no previous deploys we need to let it deploy otherwise it will
        # never get past this check!
        @logger.info "no #{@tag_prefix} tag was found, so this must be the first deployment"
        return @logger.pass("this is the first recorded deployment so is permitted")
      end

      @logger.info("the most recent deployment is #{current_tag[:name]}")

      current_deployed_rev = current_tag[:commit][:sha]
      @logger.info("which means the currently deployed commit is #{current_deployed_rev}")

      if @client.is_ancestor_of?(current_deployed_rev, new_sha)
        @logger.pass "the commit being deployed is more recent than the currently deployed commit"
      else
        @logger.fail "the commit being deployed is before the currently deployed commit, so would revert changes"
      end
    end
  end
end
