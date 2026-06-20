# frozen_string_literal: true

class ApplicationController < ActionController::Base
  layout "application"

  # Test-only auth shims. The engine's pluggable auth hooks call these by
  # symbol name; integration tests can flip the @signed_in / admin flags on
  # the host before issuing requests.
  attr_writer :current_user

  def authenticate_user!
    return true if Thread.current[:agentic_test_signed_in]
    head :unauthorized
    false
  end

  def current_user
    Thread.current[:agentic_test_user]
  end
end
