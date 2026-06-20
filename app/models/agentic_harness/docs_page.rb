# frozen_string_literal: true

# Value object representing a single Markdown documentation file from docs/.
#
# File layout convention:
#   docs/controllers/rag.md          → key "controllers/rag"
#   docs/features/rag.md             → key "features/rag"
#   docs/adr/0001-use-pgvector.md    → key "adr/0001-use-pgvector"
#
# Files starting with "_" are treated as partials and excluded from listings.
#
module AgenticHarness
class DocsPage
  def self.docs_root
    AgenticHarness.configuration.docs_root
  end

  SECTIONS = %w[features controllers api frontend adr plans runbooks strategy].freeze

  attr_reader :key, :frontmatter, :body

  # Find a single doc by key. Returns nil if the key is unsafe or the file
  # doesn't exist — never raises for missing files.
  def self.find(key)
    return nil unless safe_key?(key)

    path = docs_root.join("#{key}.md")
    return nil unless path.to_s.start_with?(docs_root.to_s)  # traversal guard
    return nil unless path.exist?

    new(key, path)
  end

  # All docs, sorted by key. Root-level files and partials (starting with _) are excluded.
  # Uses per-section globs so symlinked directories (e.g. docs/strategy → ../strategy)
  # are traversed correctly (Ruby's ** doesn't follow symlinks).
  def self.all
    entries = SECTIONS.flat_map do |section|
      section_dir = docs_root.join(section)
      next [] unless section_dir.exist?

      Dir.glob(section_dir.join("**", "*.md")).map do |f|
        # Build key relative to docs_root using the logical path (not realpath)
        # so symlinked dirs keep their section prefix (e.g. strategy/problems/P1)
        logical = Pathname.new(f).relative_path_from(section_dir).to_s.delete_suffix(".md")
        key = "#{section}/#{logical}"
        [key, Pathname.new(f)]
      end
    end

    entries
      .reject { |_, path| path.basename.to_s.start_with?("_") }
      .reject { |key, _| key.exclude?("/") }
      .uniq { |key, _| key }
      .map { |key, path| new(key, path) }
      .sort_by(&:key)
  end

  # All docs grouped by top-level section, ordered by SECTIONS constant.
  def self.by_section
    all.group_by(&:section).sort_by { |sec, _| SECTIONS.index(sec) || 99 }.to_h
  end

  # All docs whose key starts with the given directory prefix.
  # E.g. in_directory("strategy/problems") returns all strategy/problems/* pages.
  def self.in_directory(prefix)
    prefix = prefix.chomp("/")
    return [] unless safe_key?(prefix)

    all.select { |page| page.key.start_with?("#{prefix}/") || page.key == prefix }
  end

  def initialize(key, path)
    @key = key
    parse(path.read)
  end

  def title
    frontmatter["title"] || key.split("/").last.tr("-", " ").humanize
  end

  def section
    key.split("/").first
  end

  def controller_class
    frontmatter["controller"]
  end

  def routes
    Array(frontmatter["routes"])
  end

  def last_updated
    frontmatter["last_updated"]
  end

  def related_features
    Array(frontmatter["related_features"])
  end

  # Renders the Markdown body to sanitized HTML.
  def rendered_html
    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,  # docs are developer-authored; embedded HTML is intentional
      hard_wrap:   false,
      link_attributes: { rel: "noopener noreferrer" }
    )
    md = Redcarpet::Markdown.new(
      renderer,
      autolink:           true,
      tables:             true,
      fenced_code_blocks: true,
      strikethrough:      true,
      highlight:          true,
      footnotes:          true
    )
    md.render(body).html_safe  # rubocop:disable Rails/OutputSafety
  end

  private

  def self.safe_key?(key)
    key.present? &&
      key.match?(/\A[\w\-\/]+\z/) &&
      !key.include?("..") &&
      !key.start_with?("/")
  end
  private_class_method :safe_key?

  # Splits YAML frontmatter from body. Handles files with or without frontmatter.
  def parse(raw)
    if raw.start_with?("---")
      parts = raw.split(/^---\s*$/, 3)
      if parts.length == 3
        @frontmatter = YAML.safe_load(parts[1].strip, permitted_classes: [Date, Symbol]) || {}
        @body        = parts[2].lstrip
        return
      end
    end
    @frontmatter = {}
    @body        = raw
  end
end
end
