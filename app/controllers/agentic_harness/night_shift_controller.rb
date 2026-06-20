# frozen_string_literal: true

module AgenticHarness
  # Anonymous, per-worktree view of THIS worktree's own night-shift artifacts.
  #
  # Only reachable when the current process is running inside a night-shift
  # worktree (branch starts with `night-shift/` AND TASK.md exists at the
  # repo root). Outside that scenario every action returns 404, so the
  # routes are effectively invisible.
  #
  # Anonymous: the engine's pluggable auth is bypassed for this controller
  # because the worktree itself is the access control — if you can reach
  # this dev/preview host you already have the artifacts on disk.
  class NightShiftController < ApplicationController
    skip_before_action :__agentic_authenticate, raise: false
    skip_before_action :__agentic_authorize,    raise: false

    before_action :ensure_in_night_shift

    def index
      @docs = NightShifts::FileLoader.list(slug: night_shift_slug)
    end

    def document
      @result = NightShifts::FileLoader.load(slug: night_shift_slug, filename: params[:doc])
      return render_not_found unless @result

      @rendered_html = NightShifts::MarkdownRenderer.render(@result.content)
      render :document, formats: [:html]
    end

    private

    def ensure_in_night_shift
      render_not_found unless helpers.night_shift?
    end

    def render_not_found
      render plain: "Not found", status: :not_found
    end

    def night_shift_slug
      helpers.night_shift_slug
    end
  end
end
