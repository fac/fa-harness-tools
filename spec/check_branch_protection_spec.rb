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
      instance_double(FaHarnessTools::GithubClient)
    end
    let(:harness_context) do
      instance_double(FaHarnessTools::HarnessContext)
    end

    before do
      allow(harness_context).to receive(:new_commit_sha).and_return("123456")
    end

    it "returns true if commit is on branch" do
      allow(client).to receive(:branch_contains?).with("master", "123456").and_return(true)
      expect(subject.verify?).to eq([true, "master contains 123456"])
    end

    it "returns false if commit isn't on branch" do
      allow(client).to receive(:branch_contains?).with("master", "123456").and_return(false)
      expect(subject.verify?).to eq([false, "master does not contain 123456"])
    end
  end
end
