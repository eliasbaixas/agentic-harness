# frozen_string_literal: true

module AgenticHarness
  # View helpers for the per-worktree night-shift banner.
  #
  # `night_shift?` — true iff this Rails process is running inside a worktree
  # whose branch starts with `night-shift/` AND has a TASK.md at the repo root.
  # Both conditions cut down on false positives.
  module NightShiftHelper
    NIGHT_SHIFT_PREFIX = "night-shift/"

    def night_shift?
      night_shift_slug.present?
    end

    def night_shift_slug
      branch = NightShifts::Scanner.current_branch(Rails.root.to_s)
      return nil if branch.blank? || !branch.start_with?(NIGHT_SHIFT_PREFIX)
      return nil unless Rails.root.join("TASK.md").exist?

      branch.delete_prefix(NIGHT_SHIFT_PREFIX)
    end

    def night_shift_present_docs
      return [] unless night_shift?

      NightShifts::FileLoader::ALLOWED_FILENAMES.select do |name|
        Rails.root.join(name).exist?
      end
    end

    # Hosts that route per-worktree previews via a wildcard subdomain
    # (e.g. *.example.com → worktree dev server) set NIGHT_SHIFT_PARENT_DOMAIN
    # in their env; everyone else leaves it unset and `night_shift_url` is nil.
    def night_shift_parent_domain
      ENV["NIGHT_SHIFT_PARENT_DOMAIN"].presence
    end

    def night_shift_url(slug)
      domain = night_shift_parent_domain
      return nil if domain.blank?
      "https://#{slug.to_s.downcase}.#{domain}"
    end
  end
end
