describe FaHarnessTools::CheckRecentDeploy do
  describe "#verify?" do
    subject do
      described_class.new(
        client: client,
        context: harness_context,
        tag_prefix: "harness-deploy",
        allowed_rollback_count: 3,
      )
    end

    let(:client) do
      instance_double(FaHarnessTools::GithubClient)
    end
    let(:harness_context) do
      instance_double(FaHarnessTools::HarnessContext)
    end
    let(:git_tags) do
      [
        { name: "harness-deploy-production-2019-10-29T10-10-00Z", commit: { sha: "456789" } },
        { name: "harness-deploy-production-2019-10-28T11-20-00Z", commit: { sha: "345678" } },
        { name: "harness-deploy-production-2019-10-27T12-30-00Z", commit: { sha: "234567" } },
        { name: "harness-deploy-production-2019-10-26T13-40-00Z", commit: { sha: "123456" } },
      ]
    end

    before do
      allow(harness_context).to receive(:environment).and_return("production")
      allow(client).to receive(:all_deploy_tags).and_return(git_tags)
    end

    context "with no git tags" do
      let(:git_tags) { [] }

      it "returns true on first deploy" do
        allow(harness_context).to receive(:new_commit_sha).and_return("234567")
        expect(subject.verify?).to eq([true, "first deploy"])
      end
    end

    context "with one git tag" do
      let(:git_tags) do
        [
          { name: "harness-deploy-production-2019-10-26T13-40-00Z", commit: { sha: "123456" } },
        ]
      end

      it "returns true when deploying only existing tag" do
        allow(harness_context).to receive(:new_commit_sha).and_return("234567")
        allow(client).to receive(:is_ancestor_of?).with("123456", "234567").and_return(true)
        expect(subject.verify?).to eq([true, "234567 is ahead of no.3 most recent commit with \"harness-deploy\" tag"])
      end
    end

    it "returns true for latest commit beyond rollback tag" do
      allow(harness_context).to receive(:new_commit_sha).and_return("567890")
      allow(client).to receive(:is_ancestor_of?).with("234567", "567890").and_return(true)
      expect(subject.verify?).to eq([true, "567890 is ahead of no.3 most recent commit with \"harness-deploy\" tag"])
    end

    it "returns true for oldest allowed rollback tag" do
      allow(harness_context).to receive(:new_commit_sha).and_return("234567")
      allow(client).to receive(:is_ancestor_of?).with("234567", "234567").and_return(true)
      expect(subject.verify?).to eq([true, "234567 is ahead of no.3 most recent commit with \"harness-deploy\" tag"])
    end

    it "returns false for older than allowed rollback tag" do
      allow(harness_context).to receive(:new_commit_sha).and_return("123456")
      allow(client).to receive(:is_ancestor_of?).with("234567", "123456").and_return(false)
      expect(subject.verify?).to eq([false, "123456 is prior to no.3 most recent commit with \"harness-deploy\" tag"])
    end
  end
end
