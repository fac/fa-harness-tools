describe FaHarnessTools::Schedule do
  subject { FaHarnessTools::Schedule.new(schedule: "* 9-15 * * mon-thu" )}

  describe "#can_run?" do
    context "given a time within the time window" do
      it "returns true" do
        can_run = subject.can_run?(time: Time.utc(2019, 10, 28, 9, 0))
        expect(can_run).to eql true
      end
    end

    context "given a schedule on a correct day" do
      context "which is before the first hour of the schedule" do
        it "returns false" do
          can_run = subject.can_run?(time: Time.utc(2019, 10, 28, 7, 0))
          expect(can_run).to eql false
        end
      end

      context "which is after the last hour of the schedule" do
        it "returns false" do
          can_run = subject.can_run?(time: Time.utc(2019, 10, 28, 19, 0))
          expect(can_run).to eql false
        end
      end
    end

    context "given a time on an incorrect day" do
      it "returns false" do
        can_run = subject.can_run?(time: Time.utc(2019, 10, 27, 10, 0))
        expect(can_run).to eql false
      end
    end
  end

  describe "#to_s" do
    it "returns the schedule" do
      expect(subject.to_s).to eql "* 9-15 * * mon-thu"
    end
  end
end
