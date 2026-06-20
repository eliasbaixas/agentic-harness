# frozen_string_literal: true

# Safe markdown → HTML for night-shift artifacts. The input may be authored
# by an autonomous agent and shown to anonymous viewers, so:
#
# - filter_html: true       (no raw HTML pass-through)
# - safe_links_only: true   (no javascript: links)
# - escape_html: true       (HTML-escape leaf text)
# - Hard input cap:         1 MiB. Anything larger is truncated.
#
# Caller passes a string. This service does NOT take a path argument — file
# loading is the FileLoader's job, and keeping the boundary clean prevents
# accidental file-read paths from sneaking in via the renderer.
module AgenticHarness
module NightShifts
  class MarkdownRenderer
    MAX_BYTES = 1.megabyte

    def self.render(markdown)
      return "".html_safe if markdown.blank?

      truncated = markdown.byteslice(0, MAX_BYTES) || ""
      renderer = Redcarpet::Render::HTML.new(
        filter_html: true,
        escape_html: true,
        safe_links_only: true,
        no_styles: true,
        link_attributes: {rel: "noopener noreferrer", target: "_blank"}
      )
      md = Redcarpet::Markdown.new(
        renderer,
        autolink: true,
        tables: true,
        fenced_code_blocks: true,
        strikethrough: true,
        no_intra_emphasis: true,
        space_after_headers: true
      )
      md.render(truncated).html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
end
