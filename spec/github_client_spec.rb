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
    expect(Octokit::Client).to receive(:new).with(access_token: "none").and_return(octokit)
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
end
