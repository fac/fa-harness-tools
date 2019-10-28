require "time"
require "tzinfo"

module FaHarnessTools
  # Check against the time of day so you can restrict deploying to sensible
  # hours. Uses local London time by default.
  #
  # Restricts to Mon-Thu from 9am to 4pm, Fri from 9am to 12pm.
  class CheckSchedule
    def initialize(timezone: "Europe/London")
      tz = TZInfo::Timezone.get(timezone)
      @now = tz.to_local(Time.now.utc)
    end

    def verify?
      permitted = false
      case @now.wday
      when 1..4
        permitted = true if @now.hour >= 9 && @now.hour < 16
      when 5
        permitted = true if @now.hour >= 9 && @now.hour < 12
      end

      if permitted
        [true, "scheduled deploy time"]
      else
        [false, "outside deployment schedule"]
      end
    end
  end
end
