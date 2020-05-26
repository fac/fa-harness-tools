describe FaHarnessTools::CheckSchedule do
  describe "#verify?" do
    let(:logger) do
      spy(FaHarnessTools::CheckLogger, pass: true, fail: false)
    end

    before do
      allow(FaHarnessTools::CheckLogger).to receive(:new).and_return(logger)
    end

    after do
      Timecop.return
    end

    context "before 9am on Monday outside deployment window" do
      before do
        Timecop.freeze(Time.utc(2019, 10, 28, 07, 0))
      end

      it "returns false" do
        expect(subject.verify?).to be false
      end

      it "logs the fail message" do
        subject.verify?
        expect(logger).to have_received(:fail).with("outside the deployment schedule")
      end
    end

    context "at 9am on Monday inside deployment window" do
      before do
        Timecop.freeze(Time.utc(2019, 10, 28, 9, 0))
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("inside the deployment schedule")
      end

      it "include the schedule which passed the check" do
        subject.verify?
        expect(logger).to have_received(:info).with("deployments are allowed due to the following schedule: * 9-15 * * mon-thu")
      end
    end

    context "at 4pm on Monday outside deployment window" do
      before do
        Timecop.freeze(Time.utc(2019, 10, 28, 16, 0))
      end

      it "returns false" do
        expect(subject.verify?).to be false
      end

      it "logs the fail message" do
        subject.verify?
        expect(logger).to have_received(:fail).with("outside the deployment schedule")
      end
    end

    context "at 9am on Friday inside deployment window" do
      before do
        Timecop.freeze(Time.utc(2019, 11, 1, 9, 0))
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("inside the deployment schedule")
      end

      it "include the schedule which passed the check" do
        subject.verify?
        expect(logger).to have_received(:info).with("deployments are allowed due to the following schedule: * 9-11 * * fri")
      end
    end

    context "at 12pm on Friday outside deployment window" do
      before do
        Timecop.freeze(Time.utc(2019, 11, 1, 12, 0))
      end

      it "returns false" do
        expect(subject.verify?).to be false
      end

      it "logs the fail message" do
        subject.verify?
        expect(logger).to have_received(:fail).with("outside the deployment schedule")
      end
    end

    context "at 9am on Saturday outside deployment window" do
      before do
        Timecop.freeze(Time.utc(2019, 11, 2, 9, 0))
      end

      it "returns false" do
        expect(subject.verify?).to be false
      end

      it "logs the fail message" do
        subject.verify?
        expect(logger).to have_received(:fail).with("outside the deployment schedule")
      end
    end

    context "at 9am in summer time inside deployment window" do
      before do
        Timecop.freeze(Time.utc(2019, 8, 5, 8, 0))
      end

      it "returns true" do
        expect(subject.verify?).to be true
      end

      it "logs the pass message" do
        subject.verify?
        expect(logger).to have_received(:pass).with("inside the deployment schedule")
      end
    end
  end
end
