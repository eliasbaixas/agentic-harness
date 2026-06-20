# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "bundler/setup"
require File.expand_path("dummy/config/environment", __dir__)

require "rails/test_help"
require "minitest/autorun"

module AgenticHarness
  module TestHelpers
    # Swaps the engine config to point at a freshly-created tmp dir for
    # tasks_root / docs_root / night_shifts_dir, runs the block, restores
    # config + cleans up the tmp dir.
    def with_fixture_layout
      Dir.mktmpdir("agentic-harness-test-") do |tmp|
        tmp = Pathname.new(tmp)
        (tmp / "tasks/cards/2026/06").mkpath
        (tmp / "tasks/10_todo").mkpath
        (tmp / "tasks/40_done").mkpath
        (tmp / "docs/adr").mkpath
        (tmp / "shifts").mkpath

        AgenticHarness.reset_configuration!
        AgenticHarness.configure do |c|
          c.tasks_root = tmp / "tasks"
          c.docs_root = tmp / "docs"
          c.night_shifts_dir = (tmp / "shifts").to_s
          c.authenticate_with = :authenticate_user!
          c.authorize_with = ->(controller) {
            user = controller.send(:current_user)
            user.respond_to?(:admin?) && user.admin?
          }
        end

        yield tmp
      end
    ensure
      AgenticHarness.reset_configuration!
    end

    def sign_in_admin
      Thread.current[:agentic_test_signed_in] = true
      Thread.current[:agentic_test_user] = Struct.new(:admin?).new(true)
    end

    def sign_in_non_admin
      Thread.current[:agentic_test_signed_in] = true
      Thread.current[:agentic_test_user] = Struct.new(:admin?).new(false)
    end

    def sign_out_for_test
      Thread.current[:agentic_test_signed_in] = false
      Thread.current[:agentic_test_user] = nil
    end
  end
end

class ActiveSupport::TestCase
  include AgenticHarness::TestHelpers

  def teardown
    sign_out_for_test
    super
  end
end
