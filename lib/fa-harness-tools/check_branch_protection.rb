module FaHarnessTools
  # Check if the sha being deployed belongs to the given branch.
  class CheckBranchProtection
    def initialize(client:, context:, branch:)
      @client = client
      @context = context
      @branch = branch
    end

    def verify?
      new_sha = @context.new_commit_sha
      if @client.branch_contains?(@branch, new_sha)
        [true, "#{@branch} contains #{new_sha}"]
      else
        [false, "#{@branch} does not contain #{new_sha}"]
      end
    end
  end
end
