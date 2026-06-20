# frozen_string_literal: true

require "redcarpet"
require "agentic_harness/version"
require "agentic_harness/configuration"
require "agentic_harness/engine" if defined?(Rails)

module AgenticHarness
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
