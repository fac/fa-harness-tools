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
      instance_double(FaHarnessTools::HarnessContext, environment: "production")
    end
    let(:git_tags) do
      [
        { name: "harness-deploy-production-2019-10-29T10-10-00Z", tag_sha: "400000" },
        { name: "harness-deploy-production-2019-10-28T11-20-00Z", tag_sha: "300000" },
        { name: "harness-deploy-production-2019-10-27T12-30-00Z", tag_sha: "500000" },
        { name: "harness-deploy-production-2019-10-26T13-40-00Z", tag_sha: "900000" },
      ]
    end
    let(:logger) do
      spy(FaHarnessTools::CheckLogger, pass: true, fail: false)
    end

    before do
      allow(FaHarnessTools::CheckLogger).to receive(:new).and_return(logger)
      allow(client).to receive(:all_deploy_tags).and_return(git_tags)
      allow(client).to receive(:get_commit_sha_from_tag).with(git_tags[2]).and_return("234567")
    end

    context "with no git tags on first deploy" do
      let(:git_tags) { [] }

      before do
        allow(harness_context).to receive(:new_commit_sha).and_return("234567")
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("this is the first recorded deployment so is permitted")
      end
    end

    context "with one git tag and deploying the existing tag" do
      let(:git_tags) do
        [
          { name: "harness-deploy-production-2019-10-26T13-40-00Z", commit: { sha: "200000" } },
        ]
      end

      before do
        allow(client).to receive(:get_commit_sha_from_tag).with(git_tags[0]).and_return("123456")
        allow(harness_context).to receive(:new_commit_sha).and_return("234567")
        allow(client).to receive(:is_ancestor_of?).with("123456", "234567").and_return(true)
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("the commit being deployed is more recent than the last permitted rollback commit")
      end
    end

    context "with latest commit after rollback tag" do
      before do
        allow(harness_context).to receive(:new_commit_sha).and_return("567890")
        allow(client).to receive(:is_ancestor_of?).with("234567", "567890").and_return(true)
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("the commit being deployed is more recent than the last permitted rollback commit")
      end
    end

    context "with oldest allowed rollback tag" do
      before do
        allow(harness_context).to receive(:new_commit_sha).and_return("234567")
        allow(client).to receive(:is_ancestor_of?).with("234567", "234567").and_return(true)
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("the commit being deployed is more recent than the last permitted rollback commit")
      end
    end

    context "with commit older than allowed rollback tag" do
      before do
        allow(harness_context).to receive(:new_commit_sha).and_return("123456")
        allow(client).to receive(:is_ancestor_of?).with("234567", "123456").and_return(false)
      end

      it "returns false" do
        expect(subject.verify?).to be false
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:fail).with("the commit being deployed is older than the last permitted rollback commit")
      end
    end
  end
end
