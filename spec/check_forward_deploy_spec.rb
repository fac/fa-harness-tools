require "spec_helper"

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
      instance_double(FaHarnessTools::HarnessContext)
    end

    before do
      allow(harness_context).to receive(:environment).and_return("production")
      allow(harness_context).to receive(:new_commit_sha).and_return("234567")
    end

    it "returns true on first deploy" do
      allow(client).to receive(:last_deploy_tag).and_return(nil)
      expect(subject.verify?).to eq([true, "first deploy"])
    end

    it "returns true on forward deploy" do
      allow(client).to receive(:last_deploy_tag).and_return(commit: { sha: "123456" })
      allow(client).to receive(:is_ancestor_of?).with("123456", "234567").and_return(true)
      expect(subject.verify?).to eq([true, "forward deploy, 234567 is ahead of 123456"])
    end

    it "returns false on non-fast forward deploy" do
      allow(client).to receive(:last_deploy_tag).and_return(commit: { sha: "345678" })
      allow(client).to receive(:is_ancestor_of?).with("345678", "234567").and_return(false)
      expect(subject.verify?).to eq([false, "not a forward deploy, 234567 is behind 345678"])
    end
  end
end
