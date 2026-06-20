# frozen_string_literal: true

module AgenticHarness
  # Base controller for all engine controllers. Lets the host app plug its
  # own auth in via the configuration (no Devise dependency baked in).
  class ApplicationController < ::ApplicationController
    helper_method :main_app, :engine if respond_to?(:helper_method)

    before_action :__agentic_authenticate
    before_action :__agentic_authorize

    private

    def __agentic_authenticate
      method = AgenticHarness.configuration.authenticate_with
      return if method.nil?
      case method
      when Symbol then send(method) if respond_to?(method, true)
      when Proc   then instance_exec(self, &method)
      end
    end

    def __agentic_authorize
      check = AgenticHarness.configuration.authorize_with
      return if check.nil?
      ok = case check
           when Symbol then send(check)
           when Proc   then check.call(self)
           end
      return if ok
      respond_to?(:flash) && flash[:alert] = "Not authorized"
      redirect_to main_app.respond_to?(:root_path) ? main_app.root_path : "/"
    end
  end
end
