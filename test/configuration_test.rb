# frozen_string_literal: true

require "test_helper"

class AgenticHarness::ConfigurationTest < Minitest::Test
  def setup
    AgenticHarness.reset_configuration!
  end

  def teardown
    AgenticHarness.reset_configuration!
  end

  def test_version_is_a_semver_string
    assert_match(/\A\d+\.\d+\.\d+\z/, AgenticHarness::VERSION)
  end

  def test_configure_yields_the_singleton_configuration
    AgenticHarness.configure do |c|
      c.night_shifts_dir = "/tmp/shifts"
    end
    assert_equal "/tmp/shifts", AgenticHarness.configuration.night_shifts_dir
  end

  def test_expanded_night_shifts_dir_expands_tildes
    AgenticHarness.configure do |c|
      c.night_shifts_dir = "~/somewhere"
    end
    expanded = AgenticHarness.configuration.expanded_night_shifts_dir
    refute expanded.start_with?("~"), "expected ~ to expand, got #{expanded.inspect}"
  end

  def test_default_authorize_with_returns_truthy_for_admin
    fake = Class.new do
      def current_user
        Struct.new(:admin?).new(true)
      end
    end.new
    assert AgenticHarness.configuration.authorize_with.call(fake)
  end

  def test_default_authorize_with_returns_falsy_for_non_admin
    fake = Class.new do
      def current_user
        Struct.new(:admin?).new(false)
      end
    end.new
    refute AgenticHarness.configuration.authorize_with.call(fake)
  end

  def test_default_authorize_with_handles_nil_user
    fake = Class.new do
      def current_user = nil
    end.new
    refute AgenticHarness.configuration.authorize_with.call(fake)
  end

  def test_reset_configuration_replaces_singleton
    AgenticHarness.configure { |c| c.night_shifts_dir = "/x" }
    AgenticHarness.reset_configuration!
    refute_equal "/x", AgenticHarness.configuration.night_shifts_dir
  end
end
