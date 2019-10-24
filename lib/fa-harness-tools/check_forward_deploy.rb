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
    def initialize(client:, context:, tag_prefix:)
      @client = client
      @context = context
      @tag_prefix = tag_prefix
    end

    def verify?
      current_tag = @client.last_deploy_tag(
        prefix: @tag_prefix, environment: @context.environment)

      if current_tag.nil?
        # If no previous deploys we need to let it deploy otherwise it will
        # never get past this check!
        return true, "first deploy"
      end

      current_deployed_rev = current_tag[:commit][:sha]
      rev = @context.new_commit_sha

      if @client.is_ancestor_of?(current_deployed_rev, rev)
        [true, "forward deploy, #{rev} is ahead of #{current_deployed_rev}"]
      else
        [false, "not a forward deploy, #{rev} is behind #{current_deployed_rev}"]
      end
    end
  end
end
