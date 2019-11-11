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

    # Return all tags starting "harness-deploy-ENV-"
    #
    # Used to find deployments in an environment. The commit SHA of the tag is
    # in [:commit][:sha] in the returned hash.
    #
    # @return [Array[Hash]] Array of tag data hash, or [] if none
    def all_deploy_tags(prefix:, environment:)
      @octokit.tags(owner_repo).find_all do |tag|
        tag[:name].start_with?("#{prefix}-#{environment}-")
      end
    end

    # Return the last (when sorted) tag starting "harness-deploy-ENV-"
    #
    # Used to find the most recent deployment in an environment. The commit SHA
    # of the tag is in [:commit][:sha] in the returned hash.
    #
    # @return [Hash] Tag data hash, or nil if none
    def last_deploy_tag(prefix:, environment:)
      last_tag = all_deploy_tags.sort_by { |tag| tag[:name] }.last
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

    # Checks if <commit> is on branch <branch>
    #
    # @return [Bool] True is <commit> is on <branch>
    def branch_contains?(branch, commit)
      !!@octokit.commits(owner_repo, branch).find { |c| c[:sha] == commit }
    end

    # Creates a Git tag
    #
    # Arguments match Octokit::Client::Objects#create_tag, minus first repo argument
    # (http://octokit.github.io/octokit.rb/Octokit/Client/Objects.html#create_tag-instance_method)
    def create_tag(tag, message, commit_sha, *args)
      @octokit.create_ref(owner_repo, "tags/#{tag}", commit_sha)
      @octokit.create_tag(owner_repo, tag, message, commit_sha, *args)
    end
  end
end
