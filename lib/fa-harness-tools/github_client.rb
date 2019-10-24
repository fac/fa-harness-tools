require "octokit"

# Wraps the GitHub operations we're using
module FaHarnessTools
  class GithubClient
    attr_reader :owner, :repo

    def initialize(oauth_token:, owner:, repo:)
      @octokit = Octokit::Client.new(access_token: oauth_token)
      @owner = owner
      @repo = repo
    end

    def owner_repo
      "#{owner}/#{repo}"
    end

    # Return the last (when sorted) tag starting "harness-deploy-ENV-"
    #
    # Used to find the most recent deployment in an environment. The commit SHA
    # of the tag is in [:commit][:sha] in the returned hash.
    #
    # @return [Hash] Tag data hash, or nil if none
    def last_deploy_tag(prefix:, environment:)
      last_tag = @octokit.tags(owner_repo).find_all do |tag|
        tag[:name].start_with?("#{prefix}-#{environment}-")
      end.sort_by { |tag| tag[:name] }.last
      last_tag ? last_tag : nil
    end

    # Return a full commit SHA from a short SHA
    #
    # @return [String] Full commit SHA
    # @raise [LookupError] If short SHA cannot be found
    def get_commit_sha(short_sha)
      commit = @octokit.commit(owner_repo, short_sha)
      raise LookupError, "Unable to find commit #{short_sha} in Git repo" unless commit
      commit[:sha]
    end

    # Checks if <ancestor> is an ancestor of <commit>
    #
    # i.e. commit and ancestor are directly related
    #
    # @return [Bool] True is <ancestor> is ancestor of <commit>
    def is_ancestor_of?(ancestor, commit)
      !!@octokit.commits(owner_repo, commit).find { |c| c[:sha] == ancestor }
    end
  end
end
