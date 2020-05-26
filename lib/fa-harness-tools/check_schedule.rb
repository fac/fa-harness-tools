require "time"
require "tzinfo"

module FaHarnessTools
  # Check against the time of day so you can restrict deploying to sensible
  # hours.
  class CheckSchedule
    def initialize(timezone:, schedules:)
      tz = TZInfo::Timezone.get(timezone)
      @timezone = timezone
      @now = tz.to_local(Time.now.utc)
      @schedules = schedules
      @logger = CheckLogger.new(
        name: "Check deployment schedule",
        description: "Only allow deployments within certain times of the day",
      )
    end

    def verify?
      @logger.start
      @logger.info("operating in the #{@timezone} timezone")
      @logger.info("local time is #{@now}")

      permitted = @schedules.any? do |schedule|
        can_run = schedule.can_run?(time: @now)
        @logger.info("deployments are allowed due to the following schedule: #{schedule.to_s}") if can_run
        can_run
      end

      if permitted
        @logger.pass "inside the deployment schedule"
      else
        @logger.info "failed to match any schedule #{@schedules.map(&:to_s).join(", ")}"
        @logger.fail "outside the deployment schedule"
      end
    end
  end
end
