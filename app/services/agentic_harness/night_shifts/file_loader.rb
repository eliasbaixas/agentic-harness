# frozen_string_literal: true

# Loads markdown artifact files from a night-shift worktree.
#
# Three layers of validation:
#   1. Slug must match SLUG_REGEX (no `..`, no `/`).
#   2. Filename must be in ALLOWED_FILENAMES (case-insensitive — normalized).
#   3. Resolved realpath must still be under NIGHT_SHIFTS_DIR (no symlink
#      escape, no `..` traversal).
#
# Any failure returns nil — never raises, never reads an unintended file.
module AgenticHarness
module NightShifts
  class FileLoader
    SLUG_REGEX = /\A[A-Za-z0-9][A-Za-z0-9_-]*\z/
    ALLOWED_FILENAMES = %w[TASK.md DECISIONS.md PROGRESS.md RESULTS.md].freeze
    ALLOWED_INDEX = ALLOWED_FILENAMES.each_with_object({}) do |name, h|
      h[name.downcase] = name
      h[name.downcase.delete_suffix(".md")] = name
    end.freeze

    Result = Struct.new(:slug, :filename, :path, :content, :mtime, keyword_init: true)

    def self.base_dir
      Scanner.base_dir
    end

    def self.canonical_filename(input)
      return nil if input.nil?

      ALLOWED_INDEX[input.to_s.downcase]
    end

    # Loads the file for (slug, filename). Returns Result or nil.
    def self.load(slug:, filename:)
      slug = slug.to_s
      return nil unless slug.match?(SLUG_REGEX)

      canonical = canonical_filename(filename)
      return nil if canonical.nil?

      candidate = File.join(base_dir, slug, canonical)
      return nil unless File.file?(candidate)

      real_base = File.realpath(base_dir)
      real_path = File.realpath(candidate)
      return nil unless under?(real_path, real_base)

      Result.new(
        slug: slug,
        filename: canonical,
        path: real_path,
        content: File.read(real_path),
        mtime: File.mtime(real_path)
      )
    rescue Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR
      nil
    end

    # Lists allowlisted docs that exist for this slug.
    def self.list(slug:)
      slug = slug.to_s
      return [] unless slug.match?(SLUG_REGEX)

      worktree = File.join(base_dir, slug)
      return [] unless File.directory?(worktree)

      ALLOWED_FILENAMES.select { |name| File.file?(File.join(worktree, name)) }
    end

    def self.under?(path, base)
      prefixed = base.end_with?("/") ? base : "#{base}/"
      path == base || path.start_with?(prefixed)
    end
    private_class_method :under?
  end
end
end
