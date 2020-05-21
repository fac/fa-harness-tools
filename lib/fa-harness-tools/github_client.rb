require "octokit"

# Wraps the GitHub operations we're using
module FaHarnessTools
  class GithubClient
    attr_reader :owner, :repo

    def initialize(oauth_token:, owner:, repo:)
      @octokit = Octokit::Client.new(access_token: oauth_token)
      @owner = owner
      @repo = repo
      @oauth_token = oauth_token
      validate_repo
    end

    def owner_repo
      "#{owner}/#{repo}"
    end

    # Return all tags starting "harness-deploy-ENV-"
    #
    # Used to find deployments in an environment. Provides only the tag name
    # and object, though that may be an annotated tag or a commit.
    #
    # Use #get_commit_sha_from_tag to reliably find the commit that a tag
    # points to.
    #
    # @return [Array[Hash]] Array of tag data hash, or [] if none
    def all_deploy_tags(prefix:, environment:)
      # #refs is a much quicker way than #tags to pull back all tag names, so
      # we prefer this and then fetch commit information only when we need it
      @octokit.refs(owner_repo, "tags/#{prefix}-#{environment}-").map do |ref|
        {
          name: ref[:ref][10..-1], # remove refs/tags/ prefix
          object: ref[:object],
        }
      end
    rescue Octokit::NotFound
      []
    end

    # Return the last (when sorted) tag starting "harness-deploy-ENV-"
    #
    # Used to find the most recent deployment in an environment. The commit SHA
    # of the tag is in [:commit][:sha] in the returned hash.
    #
    # @return [Hash] Tag data hash, or nil if none
    def last_deploy_tag(prefix:, environment:)
      last_tag = all_deploy_tags(prefix: prefix, environment: environment).
        sort_by { |tag| tag[:name] }.last
      return nil unless last_tag

      last_tag.merge(
        commit: { sha: get_commit_sha_from_tag(last_tag) },
      )
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

    # Return a full commit SHA from a tag
    #
    # The `tag` argument should be a Hash of tag data with an :object that can
    # either be an annotated tag or a commit object.
    #
    # @return [String] Full commit SHA
    # @raise [LookupError] If tag cannot be found
    def get_commit_sha_from_tag(tag)
      case tag[:object][:type]
      when "commit"
        tag[:object][:sha]
      when "tag"
        # When a tag points to a tag, recurse into it until we find a commit object
        refed_tag = @octokit.tag(owner_repo, tag[:object][:sha])
        get_commit_sha_from_tag(refed_tag.to_h.merge(tag.slice(:name)))
      else
        raise LookupError, "Tag #{tag[:name]} points to a non-commit object (#{tag[:object].inspect})"
      end
    rescue Octokit::NotFound
      raise LookupError, "Unable to find tag #{tag.inspect} in Git repo"
    end

    # Checks if <ancestor> is an ancestor of <commit>
    #
    # i.e. commit and ancestor are directly related
    #
    # @return [Bool] True is <ancestor> is ancestor of <commit>
    def is_ancestor_of?(ancestor, commit)
      # Compare returns the merge base, the common point in history between the
      # two commits. If X is the ancestor of Y, then the merge base must be X.
      # If not, it's a different branch.
      @octokit.compare(owner_repo, ancestor, commit)[:merge_base_commit][:sha] == get_commit_sha(ancestor)
    end

    # Checks if <commit> is on branch <branch>
    #
    # @return [Bool] True is <commit> is on <branch>
    def branch_contains?(branch, commit)
      # The same implementation works for this question. We have both methods
      # to make the intent clearer and also this one is guaranteed to resolve a
      # branch name for the first argument.
      is_ancestor_of?(commit, branch)
    end

    # Creates a Git tag
    #
    # Arguments match Octokit::Client::Objects#create_tag, minus first repo argument
    # (http://octokit.github.io/octokit.rb/Octokit/Client/Objects.html#create_tag-instance_method)
    def create_tag(tag, message, commit_sha, *args)
      @octokit.create_ref(owner_repo, "tags/#{tag}", commit_sha)
      @octokit.create_tag(owner_repo, tag, message, commit_sha, *args)
    end

    private

    # Validates a repository exists.
    # Raises a `LookupError` in the event a repository can't be found.
    def validate_repo
      @octokit.repo(owner_repo)

    rescue Octokit::NotFound
      message = "Unable to find repository #{owner_repo}"
      message = "#{message}. If the repository is private, try setting GITHUB_OAUTH_TOKEN" unless @oauth_token
      raise LookupError, message
    end
  end
end
