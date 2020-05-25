module FaHarnessTools
  class HarnessContext
    attr_reader :environment

    def initialize(client:, environment:, build_no:)
      @client = client
      @environment = environment
      @build_no = build_no
    end

    def new_commit_sha
      @new_commit_sha ||= @client.get_commit_sha(@build_no)
    end
  end
end
