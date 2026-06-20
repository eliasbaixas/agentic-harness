# frozen_string_literal: true

module AgenticHarness
  # Renders documentation pages from docs/**/*.md.
  #
  # Engine routes (mounted at whatever prefix the host chose):
  #   GET /docs              → index (all docs grouped by section)
  #   GET /docs/*key         → show  (single doc, e.g. /docs/controllers/rag)
  class DocsController < ApplicationController
    def index
      @by_section = DocsPage.by_section
    end

    def show
      key = params[:key].to_s.delete_suffix(".md")
      @doc = DocsPage.find(key)

      unless @doc
        @directory_pages = DocsPage.in_directory(key)
        if @directory_pages.present?
          @directory_key = key
          render :directory
          return
        end

        @error_key = key
        render :not_found, status: :not_found
      end
    end
  end
end
