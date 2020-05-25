describe FaHarnessTools::CheckBranchProtection do
  describe "#verify?" do
    subject do
      described_class.new(
        client: client,
        context: harness_context,
        branch: "master",
      )
    end

    let(:client) do
      instance_double(FaHarnessTools::GithubClient, owner_repo: "fac/example")
    end
    let(:harness_context) do
      instance_double(FaHarnessTools::HarnessContext, new_commit_sha: "123456", environment: "prod")
    end
    let(:logger) do
      spy(FaHarnessTools::CheckLogger, pass: true, fail: false)
    end

    before do
      allow(FaHarnessTools::CheckLogger).to receive(:new).and_return(logger)
    end

    context "if commit is on branch" do
      before do
        allow(client).to receive(:branch_contains?).with("master", "123456").and_return(true)
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("master contains 123456")
      end
    end

    context "if commit isn't on branch" do
      before do
        allow(client).to receive(:branch_contains?).with("master", "123456").and_return(false)
      end

      it "returns false" do
        expect(subject.verify?).to be false
      end

      it "logs the fail message" do
        subject.verify?
        expect(logger).to have_received(:fail).with("master does not contain 123456")
      end
    end
  end
end
