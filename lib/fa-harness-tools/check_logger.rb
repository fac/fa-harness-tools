module FaHarnessTools
  class CheckLogger
    def initialize(name:, description:)
      @name = name
      @description = description
    end

    def start
      puts %{Starting "#{@name}" (#{@description})}
    end

    def info(message)
      puts "  ... #{message}"
    end

    def pass(message)
      puts "PASS: #{message}"
      true
    end

    def fail(message)
      puts "FAIL: #{message}"
      false
    end
  end
end
