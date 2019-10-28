describe FaHarnessTools::CheckSchedule do
  describe "#verify?" do
    after do
      Timecop.return
    end

    context "before 9am on Monday" do
      before do
        Timecop.freeze(Time.utc(2019, 10, 28, 07, 0))
      end

      it "returns false outside deployment window" do
        expect(subject.verify?).to eq([false, "outside deployment schedule"])
      end
    end

    context "at 9am on Monday" do
      before do
        Timecop.freeze(Time.utc(2019, 10, 28, 9, 0))
      end

      it "returns true inside deployment window" do
        expect(subject.verify?).to eq([true, "scheduled deploy time"])
      end
    end

    context "at 4pm on Monday" do
      before do
        Timecop.freeze(Time.utc(2019, 10, 28, 16, 0))
      end

      it "returns false outside deployment window" do
        expect(subject.verify?).to eq([false, "outside deployment schedule"])
      end
    end

    context "at 9am on Friday" do
      before do
        Timecop.freeze(Time.utc(2019, 11, 1, 9, 0))
      end

      it "returns true inside deployment window" do
        expect(subject.verify?).to eq([true, "scheduled deploy time"])
      end
    end

    context "at 12pm on Friday" do
      before do
        Timecop.freeze(Time.utc(2019, 11, 1, 12, 0))
      end

      it "returns false outside deployment window" do
        expect(subject.verify?).to eq([false, "outside deployment schedule"])
      end
    end

    context "at 9am on Saturday" do
      before do
        Timecop.freeze(Time.utc(2019, 11, 2, 9, 0))
      end

      it "returns false outside deployment window" do
        expect(subject.verify?).to eq([false, "outside deployment schedule"])
      end
    end

    context "at 9am in summer time" do
      before do
        Timecop.freeze(Time.utc(2019, 8, 5, 8, 0))
      end

      it "returns true inside deployment window" do
        expect(subject.verify?).to eq([true, "scheduled deploy time"])
      end
    end
  end
end
