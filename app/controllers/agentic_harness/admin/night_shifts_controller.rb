# frozen_string_literal: true

module AgenticHarness
  module Admin
    # Admin-gated cross-shift dashboard.
    #
    # Lists every directory under ~/night-shifts/ (or
    # AgenticHarness.configuration.night_shifts_dir), shows per-worktree git
    # status, and renders the four allowlisted markdown artifacts produced
    # by each shift. Auth comes from the engine's ApplicationController.
    class NightShiftsController < ApplicationController
      def index
        @shifts = NightShifts::Scanner.shifts
        @base_dir = NightShifts::Scanner.base_dir
      end

      def show
        @slug = params[:id].to_s
        @shift = NightShifts::Scanner.shifts.find { |s| s.slug == @slug }
        return render_not_found unless @shift

        @docs = NightShifts::FileLoader.list(slug: @slug)
      end

      def document
        @slug = params[:id].to_s
        @shift = NightShifts::Scanner.shifts.find { |s| s.slug == @slug }
        return render_not_found unless @shift

        @result = NightShifts::FileLoader.load(slug: @slug, filename: params[:doc])
        return render_not_found unless @result

        @rendered_html = NightShifts::MarkdownRenderer.render(@result.content)
        render :document, formats: [:html]
      end

      private

      def render_not_found
        render plain: "Not found", status: :not_found
      end
    end
  end
end
