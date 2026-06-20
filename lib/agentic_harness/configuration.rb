# frozen_string_literal: true

module AgenticHarness
  # Host-app-tunable configuration. Defaults match the layout described in
  # the project README; override anything you need in an initializer:
  #
  #   AgenticHarness.configure do |c|
  #     c.tasks_root        = Rails.root.join("backlog")
  #     c.docs_root         = Rails.root.join("documentation")
  #     c.night_shifts_dir  = "~/work/shifts"
  #     c.authenticate_with = :authenticate_user!
  #     c.authorize_with    = ->(controller) { controller.current_user&.admin? }
  #   end
  class Configuration
    attr_accessor :tasks_root, :docs_root, :night_shifts_dir,
                  :authenticate_with, :authorize_with,
                  :markdown_renderer_options

    def initialize
      @tasks_root = nil # filled in lazily so Rails.root is available
      @docs_root = nil
      @night_shifts_dir = ENV.fetch("NIGHT_SHIFTS_DIR", "~/night-shifts")
      @authenticate_with = :authenticate_user! # symbol name of a host before_action
      @authorize_with = ->(controller) { controller.respond_to?(:current_user, true) && controller.send(:current_user)&.admin? }
      @markdown_renderer_options = {}
    end

    def tasks_root
      @tasks_root ||= (defined?(Rails) ? Rails.root.join("tasks") : Pathname.new("tasks"))
      Pathname(@tasks_root)
    end

    def docs_root
      @docs_root ||= (defined?(Rails) ? Rails.root.join("docs") : Pathname.new("docs"))
      Pathname(@docs_root)
    end

    def expanded_night_shifts_dir
      File.expand_path(@night_shifts_dir.to_s)
    end
  end
end
