describe FaHarnessTools::CheckLogger do
  subject do
    described_class.new(
      name: "My logger",
      description: "Checks whether the logging helper works",
    )
  end

  describe "#start" do
    it "logs the name and description to stdout" do
      message = %{Starting "My logger" (Checks whether the logging helper works)\n}
      expect { subject.start }.to output(message).to_stdout
    end
  end

  describe "#info" do
    it "logs the message to stdout" do
      expect do
        subject.info("deploying commit 1234abc")
      end.to output("  ... deploying commit 1234abc\n").to_stdout
    end
  end

  describe "#context_info" do
    it "logs the repo, environment and commit SHA" do
      client = instance_double(FaHarnessTools::GithubClient, owner_repo: "fac/example")
      context = instance_double(FaHarnessTools::HarnessContext, new_commit_sha: "123456", environment: "prod")
      expected = "  ... we're deploying repo fac/example into environment prod\n  ... we're trying to deploy commit 123456\n"

      expect do
        subject.context_info(client, context)
      end.to output(expected).to_stdout
    end
  end

  describe "#pass" do
    it "returns true" do
      expect(subject.pass("commit can be deployed")).to be true
    end

    it "logs a PASS to stdout" do
      expect do
        subject.pass("commit can be deployed")
      end.to output("PASS: commit can be deployed\n").to_stdout
    end
  end

  describe "#fail" do
    it "returns false" do
      expect(subject.fail("this commit cannot be deployed")).to be false
    end

    it "logs a FAIL to stdout" do
      expect do
        subject.fail("this commit cannot be deployed")
      end.to output("FAIL: this commit cannot be deployed\n").to_stdout
    end
  end
end
