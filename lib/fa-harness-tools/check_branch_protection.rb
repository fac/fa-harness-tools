module FaHarnessTools
  # Check if the sha being deployed belongs to the given branch.
  class CheckBranchProtection
    def initialize(client:, context:, branch:)
      @client = client
      @context = context
      @branch = branch
      @logger = CheckLogger.new(
        name: "Check branch protection",
        description: "Only allow commits on the #{@branch} branch to be deployed",
      )
    end

    def verify?
      @logger.start
      @logger.info("we're deploying repo #{@client.owner_repo} into environment #{@context.environment}")

      new_sha = @context.new_commit_sha
      @logger.info("we're trying to deploy commit #{new_sha}")

      @logger.info("checking if #{@branch} branch contains the commit")
      if @client.branch_contains?(@branch, new_sha)
        @logger.pass "#{@branch} contains #{new_sha}"
      else
        @logger.fail "#{@branch} does not contain #{new_sha}"
      end
    end
  end
end
