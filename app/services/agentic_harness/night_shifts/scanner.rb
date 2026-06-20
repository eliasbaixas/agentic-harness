# frozen_string_literal: true

require "open3"

# Walks ~/night-shifts/* (or $NIGHT_SHIFTS_DIR) and reports per-worktree status.
#
# Read-only: no shell-outs that mutate state, no file writes. Used by the
# admin dashboard at /admin/night-shifts.
module AgenticHarness
module NightShifts
  class Scanner
    DOC_FILENAMES = %w[TASK.md DECISIONS.md PROGRESS.md RESULTS.md].freeze
    SLUG_REGEX = /\A[A-Za-z0-9][A-Za-z0-9_-]*\z/

    Shift = Struct.new(
      :slug, :path, :branch, :ahead_count, :last_commit_hash,
      :last_commit_subject, :last_commit_at, :present_docs, :latest_doc_mtime,
      keyword_init: true
    )

    def self.base_dir
      AgenticHarness.configuration.expanded_night_shifts_dir
    end

    def self.shifts
      new.shifts
    end

    # Returns the branch name for the given worktree path, or nil if it can't
    # be determined. Reads .git/HEAD directly — works in worktrees where .git
    # is a gitfile (`gitdir: ...`) pointing into the parent repo's worktrees/
    # tree.
    def self.current_branch(path = Rails.root.to_s)
      head_path = head_file_for(path)
      return nil unless head_path && File.file?(head_path)

      ref_line = File.read(head_path).strip
      return nil if ref_line.empty?

      if ref_line.start_with?("ref: ")
        ref_line.sub(/\Aref: refs\/heads\//, "")
      else
        # Detached HEAD — return the short SHA.
        ref_line[0, 12]
      end
    rescue
      nil
    end

    def self.head_file_for(path)
      git = File.join(path, ".git")
      return nil unless File.exist?(git)

      if File.file?(git)
        # gitfile: "gitdir: /abs/path/.git/worktrees/<slug>"
        contents = File.read(git).strip
        gitdir = contents.sub(/\Agitdir: /, "")
        gitdir = File.expand_path(gitdir, path) unless gitdir.start_with?("/")
        File.join(gitdir, "HEAD")
      else
        File.join(git, "HEAD")
      end
    end

    def shifts
      return [] unless Dir.exist?(self.class.base_dir)

      Dir.children(self.class.base_dir).sort.filter_map do |entry|
        next unless entry.match?(SLUG_REGEX)

        worktree = File.join(self.class.base_dir, entry)
        next unless File.directory?(worktree)
        next unless File.exist?(File.join(worktree, ".git"))

        build_shift(entry, worktree)
      end
    end

    private

    def build_shift(slug, path)
      branch = self.class.current_branch(path)
      hash, subject, ts = last_commit(path)
      present = DOC_FILENAMES.select { |f| File.file?(File.join(path, f)) }
      latest_mtime = present.map { |f| File.mtime(File.join(path, f)) }.max

      Shift.new(
        slug: slug,
        path: path,
        branch: branch,
        ahead_count: ahead_of_main(path, branch),
        last_commit_hash: hash,
        last_commit_subject: subject,
        last_commit_at: ts,
        present_docs: present,
        latest_doc_mtime: latest_mtime
      )
    end

    # Returns [short_hash, subject, time] for HEAD or nil-tuple on failure.
    def last_commit(path)
      out = git(path, "log", "-1", "--pretty=format:%h%x09%s%x09%cI")
      return [nil, nil, nil] if out.nil? || out.empty?

      hash, subject, iso = out.split("\t", 3)
      ts = iso ? Time.iso8601(iso) : nil
      [hash, subject, ts]
    rescue ArgumentError
      [nil, nil, nil]
    end

    # Number of commits on `branch` not present on origin/main / main.
    # Returns nil if neither base ref exists.
    def ahead_of_main(path, branch)
      return nil if branch.nil?

      base = git(path, "rev-parse", "--verify", "--quiet", "origin/main")
      base = git(path, "rev-parse", "--verify", "--quiet", "main") if base.nil? || base.empty?
      return nil if base.nil? || base.empty?

      out = git(path, "rev-list", "--count", "#{base.strip}..HEAD")
      out&.strip&.to_i
    end

    def git(path, *args)
      cmd = ["git", "-C", path, *args]
      out, _err, status = Open3.capture3(*cmd)
      status.success? ? out : nil
    rescue
      nil
    end
  end
end
end
