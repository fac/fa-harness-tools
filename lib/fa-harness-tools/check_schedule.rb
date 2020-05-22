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
      @timezone = timezone
      @now = tz.to_local(Time.now.utc)
      @logger = CheckLogger.new(
        name: "Check deployment schedule",
        description: "Only allow deployments within certain times of the day",
      )
    end

    def verify?
      @logger.start
      @logger.info("operating in the #{@timezone} timezone")
      @logger.info("local time is #{@now}")

      permitted = false
      case @now.wday
      when 1..4
        @logger.info("deployments are allowed between 9am to 4pm today (Mon-Thu)")
        permitted = true if @now.hour >= 9 && @now.hour < 16
      when 5
        @logger.info("deployments are allowed between 9am to 12pm today (Fri)")
        permitted = true if @now.hour >= 9 && @now.hour < 12
      end

      if permitted
        @logger.pass "inside the deployment schedule"
      else
        @logger.fail "outside the deployment schedule"
      end
    end
  end
end
