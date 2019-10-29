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
    def initialize(client:, context:, tag_prefix:, allowed_rollback_count:)
      @client = client
      @context = context
      @tag_prefix = tag_prefix
      @allowed_rollback_count = allowed_rollback_count
    end

    def verify?
      tags = @client.
        all_deploy_tags(prefix: @tag_prefix, environment: @context.environment).
        sort_by { |tag| tag[:name] }

      latest_allowed_tag = tags[@allowed_rollback_count * -1]

      if latest_allowed_tag.nil?
        # If no previous deploys we need to let it deploy otherwise it will
        # never get past this check!
        return true, "first deploy"
      end

      latest_allowed_rev = latest_allowed_tag[:commit][:sha]
      rev = @context.new_commit_sha

      if @client.is_ancestor_of?(latest_allowed_rev, rev)
        [true, "#{rev} is ahead of no.#{@allowed_rollback_count} most recent commit with #{@tag_prefix.inspect} tag"]
      else
        [false, "#{rev} is prior to no.#{@allowed_rollback_count} most recent commit with #{@tag_prefix.inspect} tag"]
      end
    end
  end
end
