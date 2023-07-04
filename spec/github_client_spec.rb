describe FaHarnessTools::GithubClient do
  subject do
    described_class.new(
      oauth_token: "none",
      owner: "fac",
      repo: "example",
    )
  end

  let(:octokit) { instance_double(Octokit::Client) }

  before do
    allow(Octokit::Client).to receive(:new).with(access_token: "none").and_return(octokit)
    allow(octokit).to receive(:connection_options=)
    allow(octokit).to receive(:repo).with("fac/example")
  end

  describe "#initialize" do
    context "when the user requests a valid repository" do
      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when the user requests an invalid repository" do
      context "and the user has specified an oauth token" do
        it "raises a LookupError with an appropriate error message" do
          expect(octokit).to receive(:repo).with("fac/not_found").and_raise Octokit::NotFound
          expect(Octokit::Client).to receive(:new).with(access_token: "AAA").and_return(octokit)

          expected_message = "Unable to find repository fac/not_found"

          expect do
            described_class.new(
              oauth_token: "AAA",
              owner: "fac",
              repo: "not_found",
            )
          end.to raise_error FaHarnessTools::LookupError, expected_message
        end
      end

      context "and the user has not specified an oauth token" do
        it "raises a LookupError with an appropriate error message" do
          expect(octokit).to receive(:repo).with("fac/private_repo").and_raise Octokit::NotFound
          expect(Octokit::Client).to receive(:new).with(access_token: nil).and_return(octokit)

          expected_message  = "Unable to find repository fac/private_repo. If the repository is private, try setting GITHUB_OAUTH_TOKEN"

          expect do
            described_class.new(
              oauth_token: nil,
              owner: "fac",
              repo: "private_repo",
            )
          end.to raise_error FaHarnessTools::LookupError, expected_message
        end
      end
    end
  end

  describe "#owner_repo" do
    it "equals owner/repo" do
      expect(subject.owner_repo).to eq("fac/example")
    end
  end

  describe "#all_deploy_tags" do
    it "should return array of names and objects" do
      tag_data = [
        {
          ref: "refs/tags/deploy-prod-example-tag",
          node_id: "MDM6UmVmMTc0MzU5Mzc6cmVmcy90YWdzL2hhcm5lc3MtZGVwbG95LXByb2QtMjAyMC0wNS0yMFQxMC0yNC0wN1o=",
          url: "https://api.github.com/repos/fac/example/git/refs/tags/deploy-prod-example-tag",
          object: {
            sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
            type: "commit",
            url: "https://api.github.com/repos/fac/example/git/commits/e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
          },
        }
      ]
      expect(octokit).to receive(:refs).with("fac/example", "tags/deploy-prod-").and_return(tag_data)

      expected = [
        {
          name: "deploy-prod-example-tag",
          object: {
            sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
            type: "commit",
            url: "https://api.github.com/repos/fac/example/git/commits/e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
          },
        }
      ]
      expect(subject.all_deploy_tags(prefix: "deploy", environment: "prod")).to eq(expected)
    end

    it "should return empty array if no matching refs found" do
      expect(octokit).to receive(:refs).with("fac/example", "tags/deploy-prod-").and_raise(Octokit::NotFound)
      expect(subject.all_deploy_tags(prefix: "deploy", environment: "prod")).to eq([])
    end
  end

  describe "#last_deploy_tag" do
    it "returns the latest tag" do
      matching_tags = [
        {
          name: "deploy-prod-2020-01-14T09-14-52Z",
          object: {
            sha: "b371aa1e4b1c37f830ef57c98250141c14e7591b",
            type: "commit",
            url: "https://api.github.com/repos/fac/example/git/commits/b371aa1e4b1c37f830ef57c98250141c14e7591b",
          },
        },
        {
          name: "deploy-prod-2020-05-20T10-24-07Z",
          object: {
            sha: "1ca5879492b8fd606df1964ea3c1e2f4520f076f",
            type: "commit",
            url: "https://api.github.com/repos/fac/example/git/commits/1ca5879492b8fd606df1964ea3c1e2f4520f076f",
          },
        },
        {
          name: "deploy-prod-2020-02-05T14-00-42Z",
          object: {
            sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
            type: "commit",
            url: "https://api.github.com/repos/fac/example/git/commits/e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
          },
        },
      ]
      expect(subject).to receive(:all_deploy_tags).with(prefix: "deploy", environment: "prod").and_return(matching_tags)

      expected = matching_tags[1].merge(commit: { sha: "1ca5879492b8fd606df1964ea3c1e2f4520f076f" })
      expect(subject.last_deploy_tag(prefix: "deploy", environment: "prod")).to eq(expected)
    end

    it "returns nil if no tags were found" do
      expect(subject).to receive(:all_deploy_tags).with(prefix: "deploy", environment: "prod").and_return([])
      expect(subject.last_deploy_tag(prefix: "deploy", environment: "prod")).to be_nil
    end
  end

  describe "#get_commit_sha" do
    it "returns the commit SHA from a short SHA" do
      commit_data = {
        sha: "09ff8ac8a27362bef300b7fc0ca387af5a82f142",
        node_id: "MDY6Q29tbWl0MjE4NTUxNjg2OjA5ZmY4YWM4YTI3MzYyYmVmMzAwYjdmYzBjYTM4N2FmNWE4MmYxNDI=",
      }
      expect(octokit).to receive(:commit).with("fac/example", "09ff8ac").and_return(commit_data)
      expect(subject.get_commit_sha("09ff8ac")).to eq("09ff8ac8a27362bef300b7fc0ca387af5a82f142")
    end

    it "raises a LookupError if the commit can't be found" do
      expect(octokit).to receive(:commit).with("fac/example", "1234567").and_return(nil)
      expect do
        subject.get_commit_sha("1234567")
      end.to raise_error(FaHarnessTools::LookupError, "Unable to find commit 1234567 in Git repo")
    end
  end

  describe "#get_commit_sha_from_tag" do
    it "returns the commit SHA from a lightweight tag" do
      tag_data = {
        ref: "refs/tags/example-tag",
        node_id: "MDM6UmVmMTc0MzU5Mzc6cmVmcy90YWdzL2hhcm5lc3MtZGVwbG95LXByb2QtMjAyMC0wNS0yMFQxMC0yNC0wN1o=",
        url: "https://api.github.com/repos/fac/example/git/refs/tags/example-tag",
        object: {
          sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
          type: "commit",
          url: "https://api.github.com/repos/fac/example/git/commits/e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
        },
      }

      expect(subject.get_commit_sha_from_tag(tag_data)).to eq("e7eabe7dd1fbe7ddf75746b6203da819e8abb65c")
    end

    it "returns the commit SHA from an annotated tag" do
      tag_data = {
        ref: "refs/tags/example-tag",
        node_id: "MDM6UmVmMTc0MzU5Mzc6cmVmcy90YWdzL2RlcGxveS1wcm9kdWN0aW9uLTIwMTctMTAtMDZUMTMtNTgtMzNa",
        url: "https://api.github.com/repos/fac/example/git/refs/tags/example-tag",
        object: {
          sha: "a199d3365096c52d263b291c681f1e6b80a58a0a",
          type: "tag",
          url: "https://api.github.com/repos/fac/example/git/tags/a199d3365096c52d263b291c681f1e6b80a58a0a",
        },
      }

      commit_data = {
        node_id: "MDM6VGFnMTc0MzU5Mzc6YTE5OWQzMzY1MDk2YzUyZDI2M2IyOTFjNjgxZjFlNmI4MGE1OGEwYQ==",
        sha: "a199d3365096c52d263b291c681f1e6b80a58a0a",
        url: "https://api.github.com/repos/fac/example/git/tags/a199d3365096c52d263b291c681f1e6b80a58a0a",
        tagger: { name: "User", email: "user@example.com", date: "2017-10-06 13:58:33 UTC" },
        object: {
          sha: "2871571664f3d6ac4ba02157b4c5ec93982031fd",
          type: "commit",
          url: "https://api.github.com/repos/fac/example/git/commits/2871571664f3d6ac4ba02157b4c5ec93982031fd"
        },
        tag: "example-tag",
        message: "Example tag message\n",
        verification: { verified: false, reason: "unsigned", signature: nil, payload: nil },
      }
      expect(octokit).to receive(:tag).with("fac/example", "a199d3365096c52d263b291c681f1e6b80a58a0a").and_return(commit_data)

      expect(subject.get_commit_sha_from_tag(tag_data)).to eq("2871571664f3d6ac4ba02157b4c5ec93982031fd")
    end

    it "raises an error for tag pointing to non-tag/commit object" do
      expect do
        subject.get_commit_sha_from_tag(object: { type: "unknown" })
      end.to raise_error(FaHarnessTools::LookupError, /non-commit object/)
    end

    it "raises an error for unknown tag SHA" do
      expect(octokit).to receive(:tag).with("fac/example", "123456").and_raise(Octokit::NotFound)
      expect do
        subject.get_commit_sha_from_tag(object: { type: "tag", sha: "123456" })
      end.to raise_error(FaHarnessTools::LookupError, /Unable to find tag/)
    end
  end

  describe "#is_ancestor_of?" do
    it "returns true when 'commit' is related to 'ancestor'" do
      compare_data = {
        url: "https://api.github.com/repos/fac/example/compare/e7eabe7...5167e6c",
        merge_base_commit: {
          sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
          node_id: "MDY6Q29tbWl0MTc0MzU5Mzc6ZTdlYWJlN2RkMWZiZTdkZGY3NTc0NmI2MjAzZGE4MTllOGFiYjY1Yw==",
        },
      }
      allow(octokit).to receive(:commit).with("fac/example", "e7eabe7").and_return(sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c")
      expect(octokit).to receive(:compare).with("fac/example", "e7eabe7", "5167e6c").and_return(compare_data)

      expect(subject.is_ancestor_of?("e7eabe7", "5167e6c")).to be true
    end

    it "returns false when 'commit' and 'ancestor' are not directly related" do
      compare_data = {
        url: "https://api.github.com/repos/fac/example/compare/5167e6c...5167e6c",
        merge_base_commit: {
          sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
          node_id: "MDY6Q29tbWl0MTc0MzU5Mzc6ZTdlYWJlN2RkMWZiZTdkZGY3NTc0NmI2MjAzZGE4MTllOGFiYjY1Yw==",
        },
      }
      allow(octokit).to receive(:commit).with("fac/example", "0d0c606").and_return(sha: "0d0c6063edffee0dd0da94a66e3caafa7bde9fea")
      expect(octokit).to receive(:compare).with("fac/example", "0d0c606", "5167e6c").and_return(compare_data)

      expect(subject.is_ancestor_of?("0d0c606", "5167e6c")).to be false
    end
  end

  describe "#branch_contains?" do
    it "returns true when 'commit' is on the branch" do
      compare_data = {
        url: "https://api.github.com/repos/fac/example/compare/master...e7eabe7",
        merge_base_commit: {
          sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
          node_id: "MDY6Q29tbWl0MTc0MzU5Mzc6ZTdlYWJlN2RkMWZiZTdkZGY3NTc0NmI2MjAzZGE4MTllOGFiYjY1Yw==",
        },
      }
      allow(octokit).to receive(:commit).with("fac/example", "e7eabe7").and_return(sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c")
      expect(octokit).to receive(:compare).with("fac/example", "e7eabe7", "master").and_return(compare_data)

      expect(subject.branch_contains?("master", "e7eabe7")).to be true
    end

    it "returns false when 'commit' and 'ancestor' are not directly related" do
      compare_data = {
        url: "https://api.github.com/repos/fac/example/compare/master...5167e6c",
        merge_base_commit: {
          sha: "e7eabe7dd1fbe7ddf75746b6203da819e8abb65c",
          node_id: "MDY6Q29tbWl0MTc0MzU5Mzc6ZTdlYWJlN2RkMWZiZTdkZGY3NTc0NmI2MjAzZGE4MTllOGFiYjY1Yw==",
        },
      }
      allow(octokit).to receive(:commit).with("fac/example", "0d0c606").and_return(sha: "0d0c6063edffee0dd0da94a66e3caafa7bde9fea")
      expect(octokit).to receive(:compare).with("fac/example", "0d0c606", "master").and_return(compare_data)

      expect(subject.branch_contains?("master", "0d0c606")).to be false
    end
  end
end
