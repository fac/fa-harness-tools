module FaHarnessTools
  # Check if the sha being deployed belongs to the given branch.
  class CheckBranchProtection
    def initialize(client:, context:, branch:, new_sha:)
      @client = client
      @context = context
      @branch = branch
      @new_sha = new_sha
      @logger = CheckLogger.new(
        name: "Check branch protection",
        description: "Only allow commits on the #{@branch} branch to be deployed",
      )
    end

    def verify?
      @logger.start
      @logger.context_info(@client, @context, @new_sha)

      @logger.info("checking if #{@branch} branch contains the commit")
      if @client.branch_contains?(@branch, @new_sha)
        @logger.pass "#{@branch} contains #{@new_sha}"
      else
        @logger.fail "#{@branch} does not contain #{@new_sha}"
      end
    end
  end
end
