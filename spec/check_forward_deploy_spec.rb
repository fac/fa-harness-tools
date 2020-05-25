describe FaHarnessTools::CheckForwardDeploy do
  describe "#verify?" do
    subject do
      described_class.new(
        client: client,
        context: harness_context,
        tag_prefix: "harness-deploy",
      )
    end

    let(:client) do
      instance_double(FaHarnessTools::GithubClient)
    end
    let(:harness_context) do
      instance_double(FaHarnessTools::HarnessContext, environment: "prod", new_commit_sha: "234567")
    end
    let(:logger) do
      spy(FaHarnessTools::CheckLogger, pass: true, fail: false)
    end

    before do
      allow(FaHarnessTools::CheckLogger).to receive(:new).and_return(logger)
    end

    context "on first deploy" do
      before do
        allow(client).to receive(:last_deploy_tag).and_return(nil)
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("this is the first recorded deployment so is permitted")
      end
    end

    context "on forward deploy" do
      before do
        allow(client).to receive(:last_deploy_tag).and_return(commit: { sha: "123456" })
        allow(client).to receive(:is_ancestor_of?).with("123456", "234567").and_return(true)
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("the commit being deployed is more recent than the currently deployed commit")
      end
    end

    context "on non-fast forward deploy" do
      before do
        allow(client).to receive(:last_deploy_tag).and_return(commit: { sha: "345678" })
        allow(client).to receive(:is_ancestor_of?).with("345678", "234567").and_return(false)
      end

      it "returns false" do
        expect(subject.verify?).to be false
      end

      it "logs the fail message" do
        subject.verify?
        expect(logger).to have_received(:fail).with("the commit being deployed is before the currently deployed commit, so would revert changes")
      end
    end
  end
end
