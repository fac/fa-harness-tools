require "pastel"

module FaHarnessTools
  class CheckLogger
    def initialize(name:, description:)
      @name = name
      @description = description
      @pastel = Pastel.new(enabled: true)
    end

    def start
      puts @pastel.cyan(@pastel.bold(@name), %{ (#{@description})})
    end

    def info(message)
      puts "  ... #{message}"
    end

    def context_info(client, context)
      info("we're deploying repo #{client.owner_repo} into environment #{context.environment}")
      info("we're trying to deploy commit #{context.new_commit_sha}")
    end

    def pass(message)
      puts @pastel.green("PASS: #{message}")
      true
    end

    def fail(message)
      puts @pastel.red("FAIL: #{message}")
      false
    end
  end
end
