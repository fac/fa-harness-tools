require 'fugit'

module FaHarnessTools
  # Creates a schedule which can be used to check if a change
  # should be deployed.
  class Schedule
    def initialize(schedule:)
      @schedule = schedule
      @cron_schedule = Fugit.parse(schedule)
    end

    def can_run?(time:)
      return false unless @cron_schedule.day_match?(time)
      return @cron_schedule.hour_match?(time)
    end

    def to_s
      return @schedule
    end
  end
end
