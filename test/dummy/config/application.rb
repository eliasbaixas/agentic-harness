# frozen_string_literal: true

require_relative "boot"

require "action_controller/railtie"
require "action_view/railtie"

# The gem under test.
require "agentic_harness"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.consider_all_requests_local = true
    config.cache_classes = false
    config.action_controller.perform_caching = false
    config.secret_key_base = "test-only-secret-key-base-not-used-for-anything-real"
    config.hosts.clear
    config.logger = Logger.new(IO::NULL)
  end
end
